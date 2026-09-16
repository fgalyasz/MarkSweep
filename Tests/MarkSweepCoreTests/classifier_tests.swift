import XCTest
@testable import MarkSweepCore

func sampleFeatures(
    id: String = "1",
    labels: [String] = ["INBOX"],
    snippet: String = "hello",
    size: Int = 100,
    from: String = "a@b.com",
    to: String = "",
    cc: String = "",
    subject: String = "Hi",
    date: Date = Date(timeIntervalSince1970: 0),
    unsubscribe: String? = nil,
    body: String? = nil
) -> MessageFeatures {
    MessageFeatures(
        id: id,
        labelIds: labels,
        snippet: snippet,
        sizeEstimate: size,
        from: from,
        to: to,
        cc: cc,
        subject: subject,
        date: date,
        listUnsubscribe: unsubscribe,
        bodyText: body
    )
}

final class ClassifierTests: XCTestCase {
    let large = 5_000_000

    func testSpamLabel() {
        let verdict = classifyMessage(sampleFeatures(labels: ["SPAM"]), largeBytes: large)
        XCTAssertEqual(verdict.kind, .spamLike)
        XCTAssertEqual(verdict.reason, "Gmail spam")
    }

    func testPromotions() {
        XCTAssertEqual(
            classifyMessage(sampleFeatures(labels: ["CATEGORY_PROMOTIONS"]), largeBytes: large).reason,
            "Promotions"
        )
    }

    func testSocial() {
        XCTAssertEqual(
            classifyMessage(sampleFeatures(labels: ["CATEGORY_SOCIAL"]), largeBytes: large).reason,
            "Social"
        )
    }

    func testNewsletter() {
        let verdict = classifyMessage(sampleFeatures(unsubscribe: "<mailto:x>"), largeBytes: large)
        XCTAssertEqual(verdict, MessageVerdict(kind: .spamLike, reason: "Newsletter"))
    }

    func testLarge() {
        let verdict = classifyMessage(sampleFeatures(size: 6_000_000), largeBytes: large)
        XCTAssertEqual(verdict.kind, .large)
        XCTAssertTrue(defaultSelected(for: .large))
        XCTAssertFalse(defaultSelected(for: .keep))
    }

    func testSpamBeatsLarge() {
        let verdict = classifyMessage(sampleFeatures(labels: ["SPAM"], size: 9_000_000), largeBytes: large)
        XCTAssertEqual(verdict.kind, .spamLike)
    }

    func testHarassment() {
        let verdict = classifyMessage(sampleFeatures(subject: "I will find you"), largeBytes: large)
        XCTAssertEqual(verdict.kind, .suspect)
        XCTAssertEqual(verdict.reason, "i will find you")
    }

    func testPhishingBody() {
        let verdict = classifyMessage(
            sampleFeatures(subject: "Hello", body: "Please verify your account now"),
            largeBytes: large
        )
        XCTAssertEqual(verdict.kind, .suspect)
    }

    func testWeakSignalKeeps() {
        let verdict = classifyMessage(sampleFeatures(subject: "Lunch tomorrow?"), largeBytes: large)
        XCTAssertEqual(verdict, MessageVerdict(kind: .keep, reason: "Looks personal"))
    }

    func testNeedsBodyOnlyInboxKeep() {
        let keep = MessageVerdict(kind: .keep, reason: "Looks personal")
        XCTAssertTrue(needsBodyFetch(sampleFeatures(labels: ["INBOX"]), verdict: keep))
        XCTAssertFalse(needsBodyFetch(sampleFeatures(labels: ["SPAM"]), verdict: keep))
        let spam = MessageVerdict(kind: .spamLike, reason: "Gmail spam")
        XCTAssertFalse(needsBodyFetch(sampleFeatures(labels: ["INBOX"]), verdict: spam))
    }

    func testRefineKeepsNonKeep() {
        let current = MessageVerdict(kind: .large, reason: "Large message")
        let refined = refineVerdict(current, features: sampleFeatures(), intelligence: HeuristicIntelligence())
        XCTAssertEqual(refined, current)
    }

    func testRefineUpgradesKeep() {
        let current = MessageVerdict(kind: .keep, reason: "Looks personal")
        let features = sampleFeatures(body: "watch your back")
        let refined = refineVerdict(current, features: features, intelligence: HeuristicIntelligence())
        XCTAssertEqual(refined.kind, .suspect)
    }

    func testHeuristicNilWhenClean() {
        XCTAssertNil(HeuristicIntelligence().classify(sampleFeatures()))
    }

    func testMatchedPhraseNegative() {
        XCTAssertNil(matchedPhrase(in: "hello", phrases: ["kys"]))
    }
}
