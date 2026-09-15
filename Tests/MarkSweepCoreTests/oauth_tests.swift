import XCTest
@testable import MarkSweepCore

final class OAuthTests: XCTestCase {
    func testBase64URLHasNoPadding() {
        let encoded = base64URLEncode(Data([0xFB, 0xEF, 0xFF]))
        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        XCTAssertFalse(encoded.contains("="))
    }

    func testPKCEChallengeIsStable() {
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        XCTAssertEqual(
            pkceChallengeS256(verifier: verifier),
            "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        )
    }

    func testMakePKCEIsUnique() {
        XCTAssertNotEqual(makePKCEChallenge().verifier, makePKCEChallenge().verifier)
        XCTAssertNotEqual(makePKCEChallenge().state, makePKCEChallenge().state)
    }

    func testAuthURLContainsPKCE() {
        let config = GoogleOAuthConfig(clientID: "cid", clientSecret: nil)
        let pkce = PKCEChallenge(verifier: "v", challenge: "ch", state: "st")
        let url = googleAuthURL(config: config, pkce: pkce, redirectURI: "http://127.0.0.1:9/")
        XCTAssertTrue(url.absoluteString.contains("client_id=cid"))
        XCTAssertTrue(url.absoluteString.contains("code_challenge=ch"))
        XCTAssertTrue(url.absoluteString.contains("state=st"))
        XCTAssertTrue(url.absoluteString.contains("gmail.modify"))
    }

    func testCallbackCode() throws {
        let url = URL(string: "http://127.0.0.1:9/?state=st&code=abc")!
        XCTAssertEqual(try oauthCallbackCode(from: url, expectedState: "st"), "abc")
    }

    func testCallbackDenied() {
        let url = URL(string: "http://127.0.0.1:9/?error=access_denied&state=st")!
        XCTAssertThrowsError(try oauthCallbackCode(from: url, expectedState: "st")) { error in
            XCTAssertEqual(error as? MarkSweepError, .oauthDenied)
        }
    }

    func testCallbackStateMismatch() {
        let url = URL(string: "http://127.0.0.1:9/?state=nope&code=abc")!
        XCTAssertThrowsError(try oauthCallbackCode(from: url, expectedState: "st")) { error in
            XCTAssertEqual(error as? MarkSweepError, .oauthStateMismatch)
        }
    }

    func testCallbackMissingCode() {
        let url = URL(string: "http://127.0.0.1:9/?state=st")!
        XCTAssertThrowsError(try oauthCallbackCode(from: url, expectedState: "st"))
    }

    func testTokenParseAndMerge() throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let data = Data("{\"access_token\":\"a\",\"expires_in\":10}".utf8)
        let token = try oauthToken(from: data, now: now)
        XCTAssertEqual(token.accessToken, "a")
        XCTAssertNil(token.refreshToken)
        XCTAssertEqual(token.expiry, now.addingTimeInterval(10))
        let previous = OAuthToken(accessToken: "old", refreshToken: "r", expiry: now)
        XCTAssertEqual(mergedToken(new: token, previous: previous).refreshToken, "r")
    }

    func testTokenNeedsRefresh() {
        let now = Date(timeIntervalSince1970: 100)
        let token = OAuthToken(accessToken: "a", refreshToken: nil, expiry: now.addingTimeInterval(30))
        XCTAssertTrue(tokenNeedsRefresh(token, now: now, skew: 60))
        XCTAssertFalse(tokenNeedsRefresh(token, now: now, skew: 10))
    }

    func testMissingClientID() {
        XCTAssertThrowsError(try googleOAuthConfig(clientID: "  ", clientSecret: nil)) { error in
            XCTAssertEqual(error as? MarkSweepError, .missingClientID)
        }
    }

    func testBlankSecretBecomesNil() throws {
        let config = try googleOAuthConfig(clientID: "id", clientSecret: "  ")
        XCTAssertNil(config.clientSecret)
        XCTAssertEqual(loopbackRedirectURI(port: 9), "http://127.0.0.1:9/")
    }

    func testTokenJSONDecodeFailure() {
        XCTAssertThrowsError(try oauthToken(from: Data("{}".utf8), now: Date())) { error in
            XCTAssertEqual(error as? MarkSweepError, .decode)
        }
    }

    func testFormBodyEncodes() {
        let body = String(data: formBody(["a": "b c"]), encoding: .utf8)
        XCTAssertEqual(body, "a=b%20c")
    }

    func testExchangeFieldsIncludeVerifier() {
        let config = GoogleOAuthConfig(clientID: "id", clientSecret: "s")
        let fields = tokenExchangeFields(code: "c", verifier: "v", config: config, redirectURI: "r")
        XCTAssertEqual(fields["code_verifier"], "v")
        XCTAssertEqual(fields["client_secret"], "s")
    }

    func testRefreshFields() {
        let config = GoogleOAuthConfig(clientID: "id", clientSecret: nil)
        let fields = tokenRefreshFields(refreshToken: "r", config: config)
        XCTAssertNil(fields["client_secret"])
        XCTAssertEqual(fields["grant_type"], "refresh_token")
    }

    func testConfigFromJSON() throws {
        let data = Data("{\"client_id\":\"id\",\"client_secret\":\"s\"}".utf8)
        let config = try oauthConfigFromJSON(data)
        XCTAssertEqual(config.clientID, "id")
        XCTAssertEqual(config.clientSecret, "s")
    }

    func testConfigFromBadJSON() {
        XCTAssertThrowsError(try oauthConfigFromJSON(Data("[]".utf8)))
    }

    func testLoadConfigPrefersEnv() throws {
        let url = URL(fileURLWithPath: "/tmp/missing-oauth-\(UUID().uuidString).json")
        let config = try loadOAuthConfig(envID: "env-id", envSecret: nil, fileURL: url)
        XCTAssertEqual(config.clientID, "env-id")
    }

    func testMemoryTokenStore() throws {
        let store = MemoryTokenStore()
        XCTAssertNil(try store.load())
        let token = OAuthToken(accessToken: "a", refreshToken: "r", expiry: Date())
        try store.save(token)
        XCTAssertEqual(try store.load(), token)
        try store.clear()
        XCTAssertNil(try store.load())
    }

    func testTokenPOSTIsForm() {
        let request = tokenPOSTRequest(fields: ["a": "b"])
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
    }
}
