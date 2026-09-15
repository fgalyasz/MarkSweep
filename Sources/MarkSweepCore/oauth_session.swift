import Foundation

public func ensureAccessToken(
    store: TokenStoring,
    transport: HTTPTransporting,
    config: GoogleOAuthConfig,
    now: Date
) async throws -> OAuthToken {
    guard let current = try store.load() else { throw MarkSweepError.tokenMissing }
    if tokenNeedsRefresh(current, now: now) == false { return current }
    return try await refreshAndStore(current: current, store: store, transport: transport, config: config, now: now)
}

public func refreshAndStore(
    current: OAuthToken,
    store: TokenStoring,
    transport: HTTPTransporting,
    config: GoogleOAuthConfig,
    now: Date
) async throws -> OAuthToken {
    guard let refresh = current.refreshToken else { throw MarkSweepError.tokenMissing }
    let request = tokenPOSTRequest(fields: tokenRefreshFields(refreshToken: refresh, config: config))
    let data = try requireHTTPData(try await transport.data(for: request))
    let merged = mergedToken(new: try oauthToken(from: data, now: now), previous: current)
    try store.save(merged)
    return merged
}

public func exchangeCodeAndStore(
    code: String,
    verifier: String,
    redirectURI: String,
    store: TokenStoring,
    transport: HTTPTransporting,
    config: GoogleOAuthConfig,
    now: Date
) async throws -> OAuthToken {
    let fields = tokenExchangeFields(code: code, verifier: verifier, config: config, redirectURI: redirectURI)
    let data = try requireHTTPData(try await transport.data(for: tokenPOSTRequest(fields: fields)))
    let token = try oauthToken(from: data, now: now)
    try store.save(token)
    return token
}
