import XCTest
@testable import MarkSweepCore

final class KeychainQueryTests: XCTestCase {
    func testBaseUsesDataProtection() {
        XCTAssertTrue(keychainUsesDataProtection(keychainBaseQuery()))
        XCTAssertEqual(keychainBaseQuery()[kSecAttrService as String] as? String, markSweepKeychainService)
        XCTAssertEqual(keychainBaseQuery()[kSecAttrAccount as String] as? String, markSweepKeychainAccount)
    }

    func testLoadAndAddKeepFlag() {
        XCTAssertTrue(keychainUsesDataProtection(keychainLoadQuery()))
        XCTAssertTrue(keychainUsesDataProtection(keychainAddQuery(data: Data())))
        XCTAssertEqual(keychainLoadQuery()[kSecReturnData as String] as? Bool, true)
    }

    func testCustomService() {
        let query = keychainBaseQuery(service: "s", account: "a")
        XCTAssertEqual(query[kSecAttrService as String] as? String, "s")
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "a")
        XCTAssertTrue(keychainUsesDataProtection(query))
    }
}
