import Foundation

public func oauthConfigFromEnv(
    clientID: String?,
    clientSecret: String?
) throws -> GoogleOAuthConfig {
    try googleOAuthConfig(clientID: clientID, clientSecret: clientSecret)
}

public func oauthConfigFromJSON(_ data: Data) throws -> GoogleOAuthConfig {
    guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw MarkSweepError.decode
    }
    let id = object["client_id"] as? String
    let secret = object["client_secret"] as? String
    return try googleOAuthConfig(clientID: id, clientSecret: secret)
}

public func defaultOAuthConfigURL() -> URL {
    let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return root.appendingPathComponent("MarkSweep/google_oauth_config.json")
}

public func loadOAuthConfig(envID: String?, envSecret: String?, fileURL: URL) throws -> GoogleOAuthConfig {
    if let config = try? oauthConfigFromEnv(clientID: envID, clientSecret: envSecret) {
        return config
    }
    let data = try Data(contentsOf: fileURL)
    return try oauthConfigFromJSON(data)
}
