import XCTest
@testable import MarkSweepCore

final class KeepTTLTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_000_000)

    func testNilKeepDaysNeverExpires() {
        XCTAssertFalse(keepRuleIsExpired(keepDays: nil, messageDate: Date.distantPast, now: now))
        XCTAssertFalse(keepRuleIsExpired(keepDays: 0, messageDate: Date.distantPast, now: now))
    }

    func testWindowBoundary() {
        let fresh = now.addingTimeInterval(-6 * secondsPerKeepDay)
        let edge = now.addingTimeInterval(-7 * secondsPerKeepDay)
        XCTAssertFalse(keepRuleIsExpired(keepDays: 7, messageDate: fresh, now: now))
        XCTAssertTrue(keepRuleIsExpired(keepDays: 7, messageDate: edge, now: now))
    }

    func testApplyProtectsInsideWindow() {
        let item = sampleItem(id: "1", from: "a@b.com", date: now.addingTimeInterval(-2 * secondsPerKeepDay))
        let rule = KeepRule(id: "r", field: .from, match: .exact, value: "a@b.com", keepDays: 7)
        let kept = applyKeepRulesToItem(item, rules: [rule], now: now)
        XCTAssertTrue(kept.isProtected)
        XCTAssertFalse(kept.isKeepExpired)
        XCTAssertEqual(kept.verdict, .keep)
        XCTAssertTrue(kept.reason.contains("7d"))
    }

    func testApplyExpiresOutsideWindow() {
        let item = sampleItem(id: "1", from: "a@b.com", date: now.addingTimeInterval(-8 * secondsPerKeepDay))
        let rule = KeepRule(id: "r", field: .from, match: .exact, value: "a@b.com", keepDays: 7)
        let expired = applyKeepRulesToItem(item, rules: [rule], now: now)
        XCTAssertFalse(expired.isProtected)
        XCTAssertTrue(expired.isKeepExpired)
        XCTAssertTrue(expired.selected)
        XCTAssertEqual(expired.verdict, .spamLike)
        XCTAssertEqual(expiredKeepItems([expired]).map(\.id), ["1"])
    }

    func testExpiredIsSweepable() {
        let item = sampleItem(id: "1", from: "a@b.com", date: now.addingTimeInterval(-8 * secondsPerKeepDay))
        let rule = KeepRule(id: "r", field: .from, match: .exact, value: "a@b.com", keepDays: 7)
        let expired = applyKeepRulesToItem(item, rules: [rule], now: now)
        XCTAssertEqual(sweepableItems([expired]).map(\.id), ["1"])
    }

    func testForeverStillProtects() {
        let item = sampleItem(id: "1", from: "a@b.com", date: Date.distantPast)
        let rule = KeepRule(id: "r", field: .from, match: .exact, value: "a@b.com")
        let kept = applyKeepRulesToItem(item, rules: [rule], now: now)
        XCTAssertTrue(kept.isProtected)
        XCTAssertFalse(kept.isKeepExpired)
    }

    func testUpsertUpdatesDays() {
        let forever = KeepRule(id: "1", field: .from, match: .exact, value: "A@B.com")
        let timed = KeepRule(id: "2", field: .from, match: .exact, value: "a@b.com", keepDays: 7)
        let next = upsertingKeepRule([forever], timed)
        XCTAssertEqual(next.count, 1)
        XCTAssertEqual(next[0].id, "1")
        XCTAssertEqual(next[0].keepDays, 7)
        XCTAssertEqual(next[0].value, "A@B.com")
        XCTAssertEqual(upsertingKeepRule(next, forever).first?.keepDays, nil)
    }

    func testExistsIncludesKeepDays() {
        let rule = KeepRule(id: "1", field: .from, match: .exact, value: "a@b.com", keepDays: 7)
        XCTAssertTrue(keepRuleExists([rule], field: .from, match: .exact, value: "a@b.com", keepDays: 7))
        XCTAssertFalse(keepRuleExists([rule], field: .from, match: .exact, value: "a@b.com", keepDays: nil))
        XCTAssertFalse(keepRuleExists([rule], field: .from, match: .exact, value: "a@b.com", keepDays: 3))
    }

    func testParseAndText() {
        XCTAssertEqual(parseKeepDays("7"), 7)
        XCTAssertEqual(parseKeepDays(" 14 "), 14)
        XCTAssertNil(parseKeepDays(""))
        XCTAssertNil(parseKeepDays("0"))
        XCTAssertEqual(keepDaysText(7), "7")
        XCTAssertEqual(keepDaysText(nil), "")
        XCTAssertEqual(keepDaysMenuTitle(30), "30 days")
    }

    func testScanStatusWithExpiry() {
        XCTAssertEqual(scanStatusWithExpiry("Scanned 2 messages.", expired: 0), "Scanned 2 messages.")
        XCTAssertTrue(scanStatusWithExpiry("Scanned 2 messages.", expired: 1).contains("Auto-trashed 1"))
    }

    func testLegacyKeepDaysDecode() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("keep-ttl.json")
        let json = """
        {"lastEmail":"a@b.com","largeBytesThreshold":9,"perQueryCap":12,"keepRules":[{"id":"r","field":"from","match":"exact","value":"a@b.com"}]}
        """
        try Data(json.utf8).write(to: url)
        let loaded = loadSettings(from: url).keepRules
        XCTAssertEqual(loaded.count, 1)
        XCTAssertNil(loaded[0].keepDays)
        try FileManager.default.removeItem(at: url)
    }

    func testKeepDaysRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("keep-days.json")
        let rule = KeepRule(id: "r", field: .from, match: .exact, value: "a@b.com", keepDays: 7)
        try saveSettings(settingsByReplacingKeepRules(.default, rules: [rule]), to: url)
        XCTAssertEqual(loadSettings(from: url).keepRules, [rule])
        try FileManager.default.removeItem(at: url)
    }

    func testMakeKeepRuleFromSuggestionKeepsDays() {
        let suggestion = KeepRuleSuggestion(field: .from, match: .exact, value: "a@b.com")
        XCTAssertEqual(makeKeepRule(from: suggestion, keepDays: 3).keepDays, 3)
        XCTAssertNil(makeKeepRule(from: suggestion).keepDays)
    }
}
