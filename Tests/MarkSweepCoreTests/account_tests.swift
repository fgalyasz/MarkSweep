import XCTest
@testable import MarkSweepCore

final class AccountTests: XCTestCase {
    func testGmailIsEnabled() {
        XCTAssertTrue(accountKindIsEnabled(.gmail))
        XCTAssertNil(accountKindComingSoon(.gmail))
        XCTAssertEqual(accountKindTitle(.gmail), "Gmail")
    }

    func testPhotosAreComingSoon() {
        XCTAssertFalse(accountKindIsEnabled(.iCloudPhotos))
        XCTAssertFalse(accountKindIsEnabled(.googlePhotos))
        XCTAssertEqual(accountKindComingSoon(.iCloudPhotos), "Coming soon")
        XCTAssertEqual(accountKindTitle(.googlePhotos), "Google Photos")
    }

    func testAllKindsListed() {
        XCTAssertEqual(AccountKind.allCases.count, 3)
    }

    func testConnectedAccountRoundTrip() throws {
        let account = ConnectedAccount(kind: .gmail, email: "a@b.com")
        let data = try JSONEncoder().encode(account)
        let loaded = try JSONDecoder().decode(ConnectedAccount.self, from: data)
        XCTAssertEqual(loaded, account)
    }
}
