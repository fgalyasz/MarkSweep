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
    @Published var snapshot: MailboxSnapshot?
    @Published var sessionSweptCount = 0
    @Published var sessionSweptBytes = 0
    var cleanablePageToken: String?

    let tokenStore: TokenStoring
    let transport: HTTPTransporting
    var settings: MarkSweepSettings
    let settingsURL: URL
    let catcher = LoopbackOAuthCatcher()

    init(
        tokenStore: TokenStoring = FileTokenStore(),
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
        Task { await refreshMailboxSnapshot() }
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
        snapshot = nil
        sessionSweptCount = 0
        sessionSweptBytes = 0
        cleanablePageToken = nil
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
            try await self.performScan()
        }
    }

    func performScan() async throws {
        let client = try await gmailClient()
        let batch = try await fetchScanBatch(client: client)
        let outcome = try await scanNewMessages(client: client, ids: batch.ids)
        applyScanOutcome(outcome, nextToken: batch.nextPageToken)
        let expiredCount = await autoTrashExpired(client: client)
        await finishScanStatus(outcome: outcome, expired: expiredCount)
    }

    func fetchScanBatch(client: GmailClient) async throws -> ScanIdBatch {
        try await collectScanIds(
            client: client,
            largeBytes: settings.largeBytesThreshold,
            cap: settings.perQueryCap,
            sleeper: TaskSleeper(),
            pageToken: items.isEmpty ? nil : cleanablePageToken
        )
    }

    func scanNewMessages(client: GmailClient, ids: [String]) async throws -> ScanOutcome {
        try await scanMessages(
            client: client,
            ids: unseenScanIds(ids, have: Set(items.map(\.id))),
            largeBytes: settings.largeBytesThreshold,
            sleeper: TaskSleeper()
        )
    }

    func applyScanOutcome(_ outcome: ScanOutcome, nextToken: String?) {
        cleanablePageToken = nextToken
        items = applyKeepRulesToItems(mergingReviewItems(items, incoming: outcome.items), rules: settings.keepRules)
        selectedID = visibleItems.first?.id
    }

    func finishScanStatus(outcome: ScanOutcome, expired: Int) async {
        await refreshMailboxSnapshot()
        let coverage = scanCoverageStatus(
            scanned: items.count,
            mailbox: snapshot?.messagesTotal ?? items.count,
            hasMore: cleanablePageToken != nil,
            stoppedEarly: outcome.stoppedEarly
        )
        statusText = scanStatusWithExpiry(coverage, expired: expired)
    }

    func sweep() async {
        await runBusy {
            let plan = sweepPlan(from: self.items)
            let client = try await self.gmailClient()
            let result = await trashSelected(client: client, ids: plan.ids)
            self.recordSweep(items: self.items, result: result)
            self.items = removeTrashed(self.items, trashedIds: result.trashedIds)
            self.statusText = sweepSummary(plan, result: result)
            self.confirmSweep = false
            await self.refreshMailboxSnapshot()
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
        await refreshMailboxSnapshot()
    }

    func recordSweep(items: [ReviewItem], result: SweepResult) {
        let bytes = bytesForIds(items, ids: result.trashedIds)
        sessionSweptCount += result.trashedIds.count
        sessionSweptBytes += bytes
        settings = settingsByAddingSweep(settings, count: result.trashedIds.count, bytes: bytes)
        try? saveSettings(settings, to: settingsURL)
    }

    func refreshMailboxSnapshot() async {
        do {
            snapshot = try await loadMailboxSnapshot()
        } catch {
            return
        }
    }

    func loadMailboxSnapshot() async throws -> MailboxSnapshot {
        let client = try await gmailClient()
        let profile = try await client.mailboxProfile()
        let quota = try? await client.storageQuota()
        return MailboxSnapshot(
            messagesTotal: profile.messagesTotal,
            quota: quota,
            sessionSweptCount: sessionSweptCount,
            sessionSweptBytes: sessionSweptBytes,
            lifetimeSweptCount: settings.sweptCount,
            lifetimeSweptBytes: settings.sweptBytes
        )
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

    func autoTrashExpired(client: GmailClient) async -> Int {
        let expired = expiredKeepItems(items)
        if expired.isEmpty { return 0 }
        let result = await trashSelected(client: client, ids: expired.map(\.id))
        recordSweep(items: items, result: result)
        items = removeTrashed(items, trashedIds: result.trashedIds)
        return result.trashedIds.count
    }

    func addKeepRule() {
        insertKeepRule(makeKeepRule())
    }

    func addKeepRule(from suggestion: KeepRuleSuggestion, keepDays: Int? = nil) {
        insertKeepRule(makeKeepRule(from: suggestion, keepDays: keepDays))
    }

    func insertKeepRule(_ rule: KeepRule) {
        let next = upsertingKeepRule(settings.keepRules, rule)
        if next == settings.keepRules {
            statusText = "That keep rule already exists."
            return
        }
        replaceKeepRules(next)
    }

    func removeKeepRule(id: String) {
        replaceKeepRules(removingKeepRule(settings.keepRules, id: id))
    }

    func removeKeepRules(at offsets: IndexSet) {
        var rules = settings.keepRules
        rules.remove(atOffsets: offsets)
        replaceKeepRules(rules)
    }

    func updateKeepRule(_ rule: KeepRule) {
        let next = updatedKeepRules(settings.keepRules, replacing: rule)
        if next == settings.keepRules { return }
        replaceKeepRules(next)
    }

    func replaceKeepRules(_ rules: [KeepRule]) {
        settings = settingsByReplacingKeepRules(settings, rules: rules)
        try? saveSettings(settings, to: settingsURL)
        items = applyKeepRulesToItems(items, rules: rules)
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
    case .tokenSaveFailed:
        return "Could not save Gmail sign-in in Application Support/MarkSweep."
    case .notConnected:
        return "Connect Gmail first."
    }
}
