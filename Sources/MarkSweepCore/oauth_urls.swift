import Foundation

public let googleAuthEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
public let googleTokenEndpoint = "https://oauth2.googleapis.com/token"

public func googleAuthQueryItems(
    config: GoogleOAuthConfig,
    pkce: PKCEChallenge,
    redirectURI: String
) -> [URLQueryItem] {
    [
        URLQueryItem(name: "client_id", value: config.clientID),
        URLQueryItem(name: "redirect_uri", value: redirectURI),
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "scope", value: gmailOAuthScopes.joined(separator: " ")),
        URLQueryItem(name: "code_challenge", value: pkce.challenge),
        URLQueryItem(name: "code_challenge_method", value: "S256"),
        URLQueryItem(name: "state", value: pkce.state),
        URLQueryItem(name: "access_type", value: "offline"),
        URLQueryItem(name: "prompt", value: "consent")
    ]
}

public func googleAuthURL(config: GoogleOAuthConfig, pkce: PKCEChallenge, redirectURI: String) -> URL {
    var parts = URLComponents(string: googleAuthEndpoint)!
    parts.queryItems = googleAuthQueryItems(config: config, pkce: pkce, redirectURI: redirectURI)
    return parts.url!
}

public func queryValue(_ items: [URLQueryItem], name: String) -> String? {
    items.first(where: { $0.name == name })?.value
}

public func oauthCallbackCode(from url: URL, expectedState: String) throws -> String {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    if queryValue(items, name: "error") != nil { throw MarkSweepError.oauthDenied }
    if queryValue(items, name: "state") != expectedState { throw MarkSweepError.oauthStateMismatch }
    let code = queryValue(items, name: "code") ?? ""
    if code.isEmpty { throw MarkSweepError.oauthDenied }
    return code
}
