import AppKit
import Combine
import Foundation
import MarkSweepCore

@MainActor
final class AppSession: ObservableObject {
    @Published var account: ConnectedAccount?
    @Published var items: [ReviewItem] = []
    @Published var filter: ReviewFilter = .all
    @Published var selectedID: String?
    @Published var errorText: String?
    @Published var statusText: String?
    @Published var isBusy = false
    @Published var confirmSweep = false
    @Published var comingSoonKind: AccountKind?

    let tokenStore: TokenStoring
    let transport: HTTPTransporting
    var settings: MarkSweepSettings
    let settingsURL: URL
    let catcher = LoopbackOAuthCatcher()

    init(
        tokenStore: TokenStoring = KeychainTokenStore(),
        transport: HTTPTransporting = URLSessionTransport(),
        settingsURL: URL = defaultSettingsURL()
    ) {
        self.tokenStore = tokenStore
        self.transport = transport
        self.settingsURL = settingsURL
        self.settings = loadSettings(from: settingsURL)
        restoreAccountFromSettings()
    }

    var visibleItems: [ReviewItem] {
        filteredItems(items, filter: filter)
    }

    var selectedItem: ReviewItem? {
        items.first(where: { $0.id == selectedID }) ?? visibleItems.first
    }

    var plan: SweepPlan { sweepPlan(from: items) }

    func restoreAccountFromSettings() {
        guard let email = settings.lastEmail, email.isEmpty == false else { return }
        guard (try? tokenStore.load()) != nil else { return }
        account = ConnectedAccount(kind: .gmail, email: email)
    }

    func choose(_ kind: AccountKind) {
        errorText = nil
        if accountKindIsEnabled(kind) {
            Task { await connectGmail() }
            return
        }
        comingSoonKind = kind
    }

    func disconnect() {
        try? tokenStore.clear()
        account = nil
        items = []
        selectedID = nil
        settings = settingsWithEmail(settings, email: nil)
        try? saveSettings(settings, to: settingsURL)
        statusText = "Disconnected."
    }

    func toggle(id: String) {
        items = toggleSelection(items, id: id)
    }

    func selectVisible(_ selected: Bool) {
        items = setVisibleSelection(items, filter: filter, selected: selected)
    }

    func scan() async {
        await runBusy {
            let client = try await self.gmailClient()
            let ids = try await collectScanIds(
                client: client,
                largeBytes: self.settings.largeBytesThreshold,
                cap: self.settings.perQueryCap
            )
            self.items = try await scanMessages(
                client: client,
                ids: ids,
                largeBytes: self.settings.largeBytesThreshold
            )
            self.selectedID = self.visibleItems.first?.id
            self.statusText = "Scanned \(self.items.count) messages."
        }
    }

    func sweep() async {
        await runBusy {
            let plan = sweepPlan(from: self.items)
            let client = try await self.gmailClient()
            let result = await trashSelected(client: client, ids: plan.ids)
            self.items = removeTrashed(self.items, trashedIds: result.trashedIds)
            self.statusText = sweepSummary(plan, result: result)
            self.confirmSweep = false
        }
    }

    func connectGmail() async {
        await runBusy {
            let config = try self.loadConnectConfig()
            let port = try firstFreeLoopbackPort()
            let redirect = loopbackRedirectURI(port: port)
            let pkce = makePKCEChallenge()
            let authURL = googleAuthURL(config: config, pkce: pkce, redirectURI: redirect)
            let redirectURL = try await self.catcher.collectRedirect(port: port) {
                NSWorkspace.shared.open(authURL)
            }
            try await self.finishOAuth(redirectURL: redirectURL, pkce: pkce, redirect: redirect, config: config)
        }
    }

    func finishOAuth(
        redirectURL: URL,
        pkce: PKCEChallenge,
        redirect: String,
        config: GoogleOAuthConfig
    ) async throws {
        let code = try oauthCallbackCode(from: redirectURL, expectedState: pkce.state)
        _ = try await exchangeCodeAndStore(
            code: code,
            verifier: pkce.verifier,
            redirectURI: redirect,
            store: tokenStore,
            transport: transport,
            config: config,
            now: Date()
        )
        let email = try await gmailClient().profileEmail()
        account = ConnectedAccount(kind: .gmail, email: email)
        settings = settingsWithEmail(settings, email: email)
        try saveSettings(settings, to: settingsURL)
        statusText = "Connected \(email)."
    }

    func gmailClient() async throws -> GmailClient {
        let config = try loadConnectConfig()
        let token = try await ensureAccessToken(
            store: tokenStore,
            transport: transport,
            config: config,
            now: Date()
        )
        return GmailClient(transport: transport, accessToken: token.accessToken)
    }

    func loadConnectConfig() throws -> GoogleOAuthConfig {
        try loadOAuthConfig(
            envID: ProcessInfo.processInfo.environment["MARKSWEEP_GOOGLE_CLIENT_ID"],
            envSecret: ProcessInfo.processInfo.environment["MARKSWEEP_GOOGLE_CLIENT_SECRET"],
            fileURL: defaultOAuthConfigURL()
        )
    }

    func runBusy(_ work: @escaping () async throws -> Void) async {
        isBusy = true
        errorText = nil
        do {
            try await work()
        } catch {
            errorText = (error as? MarkSweepError).map(errorMessage) ?? error.localizedDescription
        }
        isBusy = false
    }
}

func errorMessage(_ error: MarkSweepError) -> String {
    switch error {
    case .missingClientID:
        return "Set MARKSWEEP_GOOGLE_CLIENT_ID or add google_oauth_config.json in Application Support/MarkSweep."
    case .oauthDenied:
        return "Google sign-in was cancelled."
    case .oauthStateMismatch:
        return "OAuth state mismatch. Try Connect again."
    case .tokenMissing:
        return "Not connected."
    case .listenFailed:
        return "Could not open a local port for Google sign-in."
    case .httpStatus(let status, let detail):
        return httpStatusText(status, detail: detail)
    case .decode:
        return "Could not read a Gmail or OAuth response."
    case .notConnected:
        return "Connect Gmail first."
    }
}
