import XCTest
@testable import MarkSweepCore

final class SettingsTests: XCTestCase {
    func testMissingFileReturnsDefault() {
        let url = URL(fileURLWithPath: "/tmp/marksweep-missing-\(UUID().uuidString).json")
        XCTAssertEqual(loadSettings(from: url), .default)
    }

    func testRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("marksweep-settings.json")
        let settings = MarkSweepSettings(lastEmail: "a@b.com", largeBytesThreshold: 9, perQueryCap: 12)
        try saveSettings(settings, to: url)
        XCTAssertEqual(loadSettings(from: url), settings)
        try FileManager.default.removeItem(at: url)
    }

    func testCorruptFileReturnsDefault() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("marksweep-bad.json")
        try Data("not-json".utf8).write(to: url)
        XCTAssertEqual(loadSettings(from: url), .default)
        try FileManager.default.removeItem(at: url)
    }

    func testSettingsWithEmailClears() {
        let next = settingsWithEmail(.default, email: nil)
        XCTAssertNil(next.lastEmail)
        XCTAssertEqual(next.largeBytesThreshold, MarkSweepSettings.default.largeBytesThreshold)
    }

    func testDefaultURL() {
        XCTAssertTrue(defaultSettingsURL().path.contains("MarkSweep/settings.json"))
    }

    func testVersion() {
        XCTAssertEqual(markSweepVersion, "0.1.0")
    }

    func testMigrateOldDefaultCap() {
        let old = MarkSweepSettings(lastEmail: "a@b.com", largeBytesThreshold: 9, perQueryCap: 500)
        XCTAssertEqual(migrateSettings(old).perQueryCap, 40)
        XCTAssertEqual(migrateSettings(old).lastEmail, "a@b.com")
        XCTAssertEqual(migrateSettings(old).keepRules, [])
    }

    func testMigrateLeavesCustomCap() {
        let custom = MarkSweepSettings(lastEmail: nil, largeBytesThreshold: 9, perQueryCap: 20)
        XCTAssertEqual(migrateSettings(custom), custom)
    }

    func testScanStatusText() {
        XCTAssertEqual(scanStatusText(ScanOutcome(items: [], stoppedEarly: false)), "Scanned 0 messages.")
        XCTAssertTrue(scanStatusText(ScanOutcome(items: [], stoppedEarly: true)).contains("slow down"))
        XCTAssertTrue(scanCoverageStatus(scanned: 40, mailbox: 900, hasMore: true, stoppedEarly: false).contains("Scan again"))
        XCTAssertTrue(scanCoverageStatus(scanned: 40, mailbox: 40, hasMore: false, stoppedEarly: false).contains("Caught up"))
        XCTAssertTrue(scanCoverageStatus(scanned: 9, mailbox: 900, hasMore: true, stoppedEarly: true).contains("slow down"))
    }
}
