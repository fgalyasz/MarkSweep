import XCTest
@testable import MarkSweepCore

final class KeepRulesTests: XCTestCase {
    func testEmptyValueNeverMatches() {
        let rule = KeepRule(id: "1", field: .from, match: .contains, value: "  ")
        let fields = MessageMatchFields(from: "a@b.com", to: "", cc: "", subject: "", body: "")
        XCTAssertFalse(keepRuleMatches(rule, fields: fields))
    }

    func testContainsSubject() {
        let rule = KeepRule(id: "1", field: .subject, match: .contains, value: "Invoice")
        let hit = MessageMatchFields(from: "", to: "", cc: "", subject: "RE: invoice 12", body: "")
        let miss = MessageMatchFields(from: "", to: "", cc: "", subject: "Hello", body: "")
        XCTAssertTrue(keepRuleMatches(rule, fields: hit))
        XCTAssertFalse(keepRuleMatches(rule, fields: miss))
    }

    func testExactFromExtractsEmail() {
        let rule = KeepRule(id: "1", field: .from, match: .exact, value: "galyasz3@gmail.com")
        let fields = MessageMatchFields(
            from: "Ferenc <Galyasz3@Gmail.com>",
            to: "",
            cc: "",
            subject: "",
            body: ""
        )
        XCTAssertTrue(keepRuleMatches(rule, fields: fields))
    }

    func testExactSubjectWholeString() {
        let rule = KeepRule(id: "1", field: .subject, match: .exact, value: "Hi")
        let fields = MessageMatchFields(from: "", to: "", cc: "", subject: "Hi there", body: "")
        XCTAssertFalse(keepRuleMatches(rule, fields: fields))
    }

    func testRecipientContainsToOrCc() {
        let rule = KeepRule(id: "1", field: .recipient, match: .contains, value: "keep@x.com")
        let toHit = MessageMatchFields(from: "", to: "Keep@x.com", cc: "", subject: "", body: "")
        let ccHit = MessageMatchFields(from: "", to: "a@b.com", cc: "Keep@x.com", subject: "", body: "")
        XCTAssertTrue(keepRuleMatches(rule, fields: toHit))
        XCTAssertTrue(keepRuleMatches(rule, fields: ccHit))
    }

    func testBodyContains() {
        let rule = KeepRule(id: "1", field: .body, match: .contains, value: "family")
        let fields = MessageMatchFields(from: "", to: "", cc: "", subject: "", body: "For the family dinner")
        XCTAssertTrue(keepRuleMatches(rule, fields: fields))
    }

    func testExtractedEmails() {
        XCTAssertEqual(extractedEmails("Ann <a@b.com>, c@d.co.uk"), ["a@b.com", "c@d.co.uk"])
        XCTAssertEqual(extractedEmails("no mail"), [])
    }

    func testProtectAndRestore() {
        let item = sampleItem(id: "1", selected: true, verdict: .spamLike, from: "Ann <a@b.com>")
        let rule = KeepRule(id: "r", field: .from, match: .exact, value: "a@b.com")
        let kept = applyKeepRulesToItem(item, rules: [rule])
        XCTAssertTrue(kept.isProtected)
        XCTAssertEqual(kept.verdict, .keep)
        XCTAssertFalse(kept.selected)
        let restored = applyKeepRulesToItem(kept, rules: [])
        XCTAssertEqual(restored.verdict, .spamLike)
        XCTAssertTrue(restored.selected)
        XCTAssertFalse(restored.isProtected)
    }

    func testToggleAndSweepSkipProtected() {
        let item = sampleItem(id: "1", selected: true, isProtected: true)
        XCTAssertTrue(toggleSelection([item], id: "1")[0].selected)
        XCTAssertEqual(sweepPlan(from: [item]).count, 0)
    }

    func testSelectVisibleSkipsProtected() {
        let items = [
            sampleItem(id: "1", selected: false, isProtected: true),
            sampleItem(id: "2", selected: false)
        ]
        let next = setVisibleSelection(items, filter: .all, selected: true)
        XCTAssertFalse(next[0].selected)
        XCTAssertTrue(next[1].selected)
    }

    func testTitles() {
        XCTAssertEqual(keepFieldTitle(.from), "From")
        XCTAssertEqual(keepFieldTitle(.recipient), "To or Cc")
        XCTAssertEqual(keepMatchTitle(.exact), "Exact")
        XCTAssertEqual(KeepField.allCases.count, 6)
    }

    func testSettingsKeepRulesRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("keep-rules.json")
        let rule = KeepRule(id: "r", field: .from, match: .exact, value: "a@b.com")
        let settings = settingsByReplacingKeepRules(.default, rules: [rule])
        try saveSettings(settings, to: url)
        XCTAssertEqual(loadSettings(from: url).keepRules, [rule])
        try FileManager.default.removeItem(at: url)
    }

    func testLegacySettingsOmitsKeepRules() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-keep.json")
        try Data("{\"lastEmail\":\"a@b.com\",\"largeBytesThreshold\":9,\"perQueryCap\":12}".utf8).write(to: url)
        XCTAssertEqual(loadSettings(from: url).keepRules, [])
        try FileManager.default.removeItem(at: url)
    }

    func testRuleSetters() {
        let rule = KeepRule(id: "1", field: .from, match: .contains, value: "a")
        XCTAssertEqual(ruleBySettingField(rule, .subject).field, .subject)
        XCTAssertEqual(ruleBySettingMatch(rule, .exact).match, .exact)
        XCTAssertEqual(ruleBySettingValue(rule, "b").value, "b")
        XCTAssertEqual(ruleBySettingKeepDays(rule, 7).keepDays, 7)
        XCTAssertNil(ruleBySettingKeepDays(rule, 0).keepDays)
    }

    func testMatchFieldsFromFeatures() {
        let features = sampleFeatures(from: "a@b.com", to: "t@x.com", cc: "c@x.com", subject: "Hi", body: "Body")
        let fields = matchFields(from: features)
        XCTAssertEqual(fields.to, "t@x.com")
        XCTAssertTrue(fields.body.contains("Body"))
    }

    func testInsertRejectsDuplicate() {
        let rule = KeepRule(id: "1", field: .from, match: .exact, value: "A@B.com")
        let copy = KeepRule(id: "2", field: .from, match: .exact, value: " a@b.com ")
        XCTAssertEqual(insertingKeepRule([rule], copy), [rule])
        XCTAssertEqual(insertingKeepRule([], rule).count, 1)
    }

    func testUpdateRejectsDuplicate() {
        let a = KeepRule(id: "1", field: .from, match: .exact, value: "a@b.com")
        let b = KeepRule(id: "2", field: .subject, match: .contains, value: "x")
        let clash = KeepRule(id: "2", field: .from, match: .exact, value: "a@b.com")
        XCTAssertEqual(updatedKeepRules([a, b], replacing: clash), [a, b])
    }

    func testRemoveAndUnique() {
        let a = KeepRule(id: "1", field: .from, match: .exact, value: "a@b.com")
        let b = KeepRule(id: "2", field: .from, match: .exact, value: "A@B.com")
        XCTAssertEqual(removingKeepRule([a, b], id: "1"), [b])
        XCTAssertEqual(uniqueKeepRules([a, b]).map(\.id), ["1"])
    }

    func testSuggestionsFromMessage() {
        let fields = MessageMatchFields(
            from: "Ann <a@b.com>",
            to: "you@x.com",
            cc: "",
            subject: "Hello",
            body: "Line one\nLine two"
        )
        let titles = keepRuleSuggestions(from: fields).map(keepSuggestionTitle)
        XCTAssertTrue(titles.contains("From: a@b.com"))
        XCTAssertTrue(titles.contains("To: you@x.com"))
        XCTAssertTrue(titles.contains("Subject: Hello"))
        XCTAssertEqual(keepRuleSuggestion(field: .body, fields: fields)?.match, .contains)
        XCTAssertNil(keepRuleSuggestion(field: .cc, fields: fields))
    }

    func testUniquedSettings() {
        let a = KeepRule(id: "1", field: .from, match: .contains, value: "x")
        let b = KeepRule(id: "2", field: .from, match: .contains, value: "x")
        let settings = settingsByReplacingKeepRules(.default, rules: [a, b])
        XCTAssertEqual(uniquedKeepSettings(settings).keepRules.map(\.id), ["1"])
    }
}
