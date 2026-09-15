import XCTest
@testable import MarkSweepCore

final class PreviewTests: XCTestCase {
    func testStripsScript() {
        let raw = "<html><script>alert(1)</script><p>Hi&nbsp;there</p></html>"
        XCTAssertEqual(previewText(from: raw), "Hi there")
    }

    func testTruncates() {
        XCTAssertEqual(truncate("abcdef", maxLength: 3), "abc")
        XCTAssertEqual(truncate("ab", maxLength: 3), "ab")
    }

    func testPreviewPrefersBody() {
        let features = sampleFeatures(snippet: "snip", body: "<b>Body</b>")
        XCTAssertEqual(previewForMessage(features), "Body")
    }

    func testPreviewFallsBackToSnippet() {
        let features = sampleFeatures(snippet: "<i>Snip</i>", body: nil)
        XCTAssertEqual(previewForMessage(features), "Snip")
    }

    func testEmptyBodyUsesSnippet() {
        let features = sampleFeatures(snippet: "only", body: "")
        XCTAssertEqual(previewForMessage(features), "only")
    }

    func testEntities() {
        XCTAssertEqual(decodeHTMLEntities("&lt;a&gt;&amp;&quot;"), "<a>&\"")
    }

    func testCollapseWhitespace() {
        XCTAssertEqual(collapseWhitespace("a \n\t b"), "a b")
    }
}
