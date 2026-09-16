import XCTest
@testable import MarkSweepCore

func sampleItem(
    id: String,
    selected: Bool = true,
    verdict: MessageVerdictKind = .spamLike,
    reason: String = "Gmail spam",
    size: Int = 10,
    spamFolder: Bool = false
) -> ReviewItem {
    ReviewItem(
        id: id,
        selected: selected,
        verdict: verdict,
        reason: reason,
        subject: "S\(id)",
        sender: "s@x.com",
        date: Date(timeIntervalSince1970: 0),
        sizeBytes: size,
        preview: "p",
        isSpamFolder: spamFolder
    )
}

final class ReviewQueueTests: XCTestCase {
    func testFilters() {
        let items = [
            sampleItem(id: "1", verdict: .suspect),
            sampleItem(id: "2", verdict: .large),
            sampleItem(id: "3", spamFolder: true)
        ]
        XCTAssertEqual(matchingCount(items, filter: .all), 3)
        XCTAssertEqual(filteredItems(items, filter: .suspect).map(\.id), ["1"])
        XCTAssertEqual(filteredItems(items, filter: .large).map(\.id), ["2"])
        XCTAssertEqual(filteredItems(items, filter: .spamFolder).map(\.id), ["3"])
    }

    func testToggleAndHiddenSelection() {
        let items = [sampleItem(id: "1"), sampleItem(id: "2")]
        let toggled = toggleSelection(items, id: "1")
        XCTAssertFalse(toggled[0].selected)
        XCTAssertTrue(toggled[1].selected)
        let visibleOff = setVisibleSelection(toggled, filter: .all, selected: false)
        XCTAssertTrue(visibleOff.allSatisfy { $0.selected == false })
    }

    func testSetVisibleLeavesHidden() {
        let items = [
            sampleItem(id: "1", verdict: .suspect),
            sampleItem(id: "2", verdict: .keep, reason: "Looks personal")
        ]
        let next = setVisibleSelection(items, filter: .suspect, selected: false)
        XCTAssertFalse(next[0].selected)
        XCTAssertTrue(next[1].selected)
    }

    func testReviewItemFromFeatures() {
        let features = sampleFeatures(labels: ["SPAM"], subject: "Win")
        let item = reviewItem(from: features, verdict: classifyMessage(features, largeBytes: 5_000_000))
        XCTAssertTrue(item.selected)
        XCTAssertTrue(item.isSpamFolder)
        XCTAssertEqual(item.subject, "Win")
    }

    func testMatchingCount() {
        let items = [sampleItem(id: "1", verdict: .suspect), sampleItem(id: "2", verdict: .large)]
        XCTAssertEqual(matchingCount(items, filter: .suspect), 1)
        XCTAssertEqual(matchingCount(items, filter: .all), 2)
        XCTAssertEqual(matchingCount([], filter: .all), 0)
    }

    func testFilterTitles() {
        XCTAssertEqual(reviewFilterTitle(.all), "All")
        XCTAssertEqual(reviewFilterTitle(.spamFolder), "Spam folder")
        XCTAssertEqual(ReviewFilter.allCases.count, 4)
    }
}

final class SweepTests: XCTestCase {
    func testPlanIgnoresUnchecked() {
        let items = [sampleItem(id: "1", selected: true, size: 20), sampleItem(id: "2", selected: false, size: 50)]
        let plan = sweepPlan(from: items)
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan.bytes, 20)
        XCTAssertEqual(plan.ids, ["1"])
    }

    func testChunkIds() {
        XCTAssertEqual(chunkIds(Array(repeating: "a", count: 0)).count, 0)
        XCTAssertEqual(chunkIds(["a", "b"], size: 1), [["a"], ["b"]])
        XCTAssertEqual(chunkIds(Array(repeating: "x", count: 1001), size: 1000).count, 2)
        XCTAssertEqual(chunkIds(["a"], size: 0).count, 0)
    }

    func testRemoveTrashed() {
        let items = [sampleItem(id: "1"), sampleItem(id: "2")]
        XCTAssertEqual(removeTrashed(items, trashedIds: ["1"]).map(\.id), ["2"])
    }

    func testSummary() {
        let plan = SweepPlan(ids: ["1", "2"], count: 2, bytes: 10)
        let result = SweepResult(trashedIds: ["1"], failedIds: ["2"])
        XCTAssertTrue(sweepSummary(plan, result: result).contains("Moved 1 of 2"))
        XCTAssertTrue(sweepSummary(plan, result: result).contains("Failed: 1"))
    }

    func testFormatBytesNonEmpty() {
        XCTAssertFalse(formatBytes(1024).isEmpty)
    }

    func testUniqueIdsPreserveOrder() {
        XCTAssertEqual(uniqueIds(["b", "a", "b"]), ["b", "a"])
    }
}
