import Foundation

public protocol TokenStoring {
    func load() throws -> OAuthToken?
    func save(_ token: OAuthToken) throws
    func clear() throws
}

public final class MemoryTokenStore: TokenStoring {
    private var token: OAuthToken?

    public init(token: OAuthToken? = nil) {
        self.token = token
    }

    public func load() throws -> OAuthToken? { token }

    public func save(_ token: OAuthToken) throws { self.token = token }

    public func clear() throws { token = nil }
}
