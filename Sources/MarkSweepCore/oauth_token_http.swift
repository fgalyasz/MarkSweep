import Foundation

struct GoogleTokenJSON: Decodable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int?
}

public func oauthToken(from data: Data, now: Date) throws -> OAuthToken {
    guard let decoded = try? JSONDecoder().decode(GoogleTokenJSON.self, from: data) else {
        throw MarkSweepError.decode
    }
    let seconds = TimeInterval(decoded.expires_in ?? 3600)
    return OAuthToken(
        accessToken: decoded.access_token,
        refreshToken: decoded.refresh_token,
        expiry: now.addingTimeInterval(seconds)
    )
}

public func formBody(_ fields: [String: String]) -> Data {
    let items = fields.map { key, value in
        "\(urlFormEncode(key))=\(urlFormEncode(value))"
    }
    return Data(items.joined(separator: "&").utf8)
}

public func urlFormEncode(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-._~")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}

public func tokenExchangeFields(
    code: String,
    verifier: String,
    config: GoogleOAuthConfig,
    redirectURI: String
) -> [String: String] {
    var fields = [
        "code": code,
        "client_id": config.clientID,
        "redirect_uri": redirectURI,
        "grant_type": "authorization_code",
        "code_verifier": verifier
    ]
    if let secret = config.clientSecret { fields["client_secret"] = secret }
    return fields
}

public func tokenRefreshFields(refreshToken: String, config: GoogleOAuthConfig) -> [String: String] {
    var fields = [
        "refresh_token": refreshToken,
        "client_id": config.clientID,
        "grant_type": "refresh_token"
    ]
    if let secret = config.clientSecret { fields["client_secret"] = secret }
    return fields
}

public func tokenPOSTRequest(fields: [String: String]) -> URLRequest {
    var request = URLRequest(url: URL(string: googleTokenEndpoint)!)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = formBody(fields)
    return request
}
