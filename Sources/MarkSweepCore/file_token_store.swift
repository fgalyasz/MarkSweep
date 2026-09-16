import Foundation

public func defaultTokenURL() -> URL {
    defaultSettingsURL().deletingLastPathComponent().appendingPathComponent("gmail_oauth_token.json")
}

public final class FileTokenStore: TokenStoring {
    let url: URL

    public init(url: URL = defaultTokenURL()) {
        self.url = url
    }

    public func load() throws -> OAuthToken? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(OAuthToken.self, from: data)
    }

    public func save(_ token: OAuthToken) throws {
        do {
            try writeTokenFile(token, to: url)
        } catch {
            throw MarkSweepError.tokenSaveFailed
        }
    }

    public func clear() throws {
        try? FileManager.default.removeItem(at: url)
    }
}

func writeTokenFile(_ token: OAuthToken, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try JSONEncoder().encode(token).write(to: url, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
}
