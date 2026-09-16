import XCTest
@testable import MarkSweepCore

final class MailboxStatsTests: XCTestCase {
    func testParseProfileCount() throws {
        let data = Data("{\"emailAddress\":\"a@b.com\",\"messagesTotal\":12}".utf8)
        let profile = try parseGmailProfile(data: data)
        XCTAssertEqual(profile.email, "a@b.com")
        XCTAssertEqual(profile.messagesTotal, 12)
    }

    func testParseProfileMissingCount() throws {
        XCTAssertEqual(try parseGmailProfile(data: Data("{\"emailAddress\":\"a@b.com\"}".utf8)).messagesTotal, 0)
    }

    func testParseDriveQuota() throws {
        let data = Data("{\"storageQuota\":{\"limit\":\"150\",\"usage\":\"40\"}}".utf8)
        let quota = try parseDriveQuota(data: data)
        XCTAssertEqual(quota.usage, 40)
        XCTAssertEqual(quota.limit, 150)
        XCTAssertEqual(storageRemaining(quota), 110)
    }

    func testParseDriveQuotaUnlimited() throws {
        let quota = try parseDriveQuota(data: Data("{\"storageQuota\":{\"usage\":\"9\"}}".utf8))
        XCTAssertNil(quota.limit)
        XCTAssertNil(storageRemaining(quota))
        XCTAssertTrue(quotaUsageLine(quota).contains("no plan limit"))
    }

    func testParseDriveQuotaBad() {
        XCTAssertThrowsError(try parseDriveQuota(data: Data("[]".utf8)))
    }

    func testQuotaLineLimited() {
        let snapshot = MailboxSnapshot(
            messagesTotal: 3,
            quota: StorageQuota(usage: 40, limit: 150),
            sessionSweptCount: 1,
            sessionSweptBytes: 10,
            lifetimeSweptCount: 2,
            lifetimeSweptBytes: 20
        )
        XCTAssertEqual(mailboxCountLine(snapshot), "3 messages in mailbox")
        XCTAssertTrue(mailboxQuotaLine(snapshot).contains("free"))
        XCTAssertTrue(mailboxCleanedSessionLine(snapshot).contains("1"))
        XCTAssertTrue(mailboxCleanedLifetimeLine(snapshot).contains("2"))
    }

    func testQuotaUnavailable() {
        let snapshot = MailboxSnapshot(
            messagesTotal: 0,
            quota: nil,
            sessionSweptCount: 0,
            sessionSweptBytes: 0,
            lifetimeSweptCount: 0,
            lifetimeSweptBytes: 0
        )
        XCTAssertEqual(mailboxQuotaLine(snapshot), "Google storage unavailable")
    }

    func testShowingCount() {
        XCTAssertEqual(showingCountLine(visible: 1, total: 175), "Showing 1 of 175")
    }

    func testBytesForIds() {
        let items = [sampleItem(id: "1", size: 10), sampleItem(id: "2", size: 7)]
        XCTAssertEqual(bytesForIds(items, ids: ["2", "9"]), 7)
        XCTAssertEqual(bytesForIds(items, ids: []), 0)
    }

    func testSettingsAddSweep() {
        let next = settingsByAddingSweep(.default, count: 3, bytes: 9)
        XCTAssertEqual(next.sweptCount, 3)
        XCTAssertEqual(next.sweptBytes, 9)
    }

    func testLegacySettingsJSON() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-ms.json")
        try Data("{\"lastEmail\":\"a@b.com\",\"largeBytesThreshold\":9,\"perQueryCap\":12}".utf8).write(to: url)
        let loaded = loadSettings(from: url)
        XCTAssertEqual(loaded.lastEmail, "a@b.com")
        XCTAssertEqual(loaded.sweptCount, 0)
        try FileManager.default.removeItem(at: url)
    }

    func testDriveUnusedAPIText() {
        let text = unusedAPIText("Google Drive API has not been used in project 1 before or it is disabled.")
        XCTAssertTrue(text.contains("Drive API"))
    }

    func testClientStorageQuota() async throws {
        let body = try jsonData(["storageQuota": ["limit": "20", "usage": "5"]])
        let transport = ScriptedTransport(queue: [(200, body)])
        let client = GmailClient(transport: transport, accessToken: "t")
        let quota = try await client.storageQuota()
        XCTAssertEqual(quota.limit, 20)
        XCTAssertEqual(storageRemaining(quota), 15)
    }
}