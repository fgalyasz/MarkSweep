import XCTest
@testable import MarkSweepCore

final class FileTokenStoreTests: XCTestCase {
    func testDefaultTokenURL() {
        XCTAssertTrue(defaultTokenURL().path.contains("MarkSweep/gmail_oauth_token.json"))
    }

    func testRoundTripAndClear() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("token-\(UUID().uuidString).json")
        let store = FileTokenStore(url: url)
        let token = OAuthToken(accessToken: "a", refreshToken: "r", expiry: Date(timeIntervalSince1970: 9))
        XCTAssertNil(try store.load())
        try store.save(token)
        XCTAssertEqual(try store.load(), token)
        let mode = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(mode?.uint16Value, 0o600)
        try store.clear()
        XCTAssertNil(try store.load())
    }

    func testCorruptFileLoadsNil() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bad-token-\(UUID().uuidString).json")
        try Data("{}".utf8).write(to: url)
        XCTAssertNil(try FileTokenStore(url: url).load())
        try FileManager.default.removeItem(at: url)
    }

    func testSaveFailure() throws {
        let blocker = FileManager.default.temporaryDirectory.appendingPathComponent("not-dir-\(UUID().uuidString)")
        try Data().write(to: blocker)
        let store = FileTokenStore(url: blocker.appendingPathComponent("gmail_oauth_token.json"))
        let token = OAuthToken(accessToken: "a", refreshToken: nil, expiry: Date())
        XCTAssertThrowsError(try store.save(token)) { error in
            XCTAssertEqual(error as? MarkSweepError, .tokenSaveFailed)
        }
        try FileManager.default.removeItem(at: blocker)
    }
}
