import Foundation

public struct OAuthToken: Equatable, Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiry: Date

    public init(accessToken: String, refreshToken: String?, expiry: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiry = expiry
    }
}

public func tokenNeedsRefresh(_ token: OAuthToken, now: Date, skew: TimeInterval = 60) -> Bool {
    token.expiry <= now.addingTimeInterval(skew)
}

public func mergedToken(new: OAuthToken, previous: OAuthToken) -> OAuthToken {
    OAuthToken(
        accessToken: new.accessToken,
        refreshToken: new.refreshToken ?? previous.refreshToken,
        expiry: new.expiry
    )
}
