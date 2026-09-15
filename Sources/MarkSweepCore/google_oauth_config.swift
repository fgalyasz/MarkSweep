import Foundation

public struct GoogleOAuthConfig: Equatable {
    public let clientID: String
    public let clientSecret: String?

    public init(clientID: String, clientSecret: String?) {
        self.clientID = clientID
        self.clientSecret = clientSecret
    }
}

public let gmailOAuthScopes = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.modify"
]

public func googleOAuthConfig(clientID: String?, clientSecret: String?) throws -> GoogleOAuthConfig {
    let id = (clientID ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if id.isEmpty { throw MarkSweepError.missingClientID }
    let secret = clientSecret?.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedSecret = (secret ?? "").isEmpty ? nil : secret
    return GoogleOAuthConfig(clientID: id, clientSecret: trimmedSecret)
}

public func loopbackRedirectURI(port: UInt16) -> String {
    "http://127.0.0.1:\(port)/"
}
