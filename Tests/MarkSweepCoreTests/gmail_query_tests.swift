import XCTest
@testable import MarkSweepCore

final class GmailQueryTests: XCTestCase {
    func testQueriesIncludeCaps() {
        let queries = gmailScanQueries(largeMegabytes: 5)
        XCTAssertEqual(queries[0], "in:spam")
        XCTAssertEqual(queries[3], "larger:5M")
        XCTAssertTrue(queries.contains("in:inbox newer_than:365d"))
    }

    func testLargeMegabytesFloor() {
        XCTAssertEqual(largeMegabytes(fromBytes: 100), 1)
        XCTAssertEqual(largeMegabytes(fromBytes: 5_000_000), 5)
    }

    func testListURL() {
        let url = gmailListURL(query: "in:spam", pageToken: "n", maxResults: 50)
        XCTAssertTrue(url.absoluteString.contains("q=in:spam") || url.absoluteString.contains("q=in%3Aspam"))
        XCTAssertTrue(url.absoluteString.contains("pageToken=n"))
        XCTAssertTrue(url.absoluteString.contains("maxResults=50"))
    }

    func testMessageURLMetadataHeaders() {
        let url = gmailMessageURL(id: "abc", format: .metadata)
        XCTAssertTrue(url.absoluteString.contains("format=metadata"))
        XCTAssertTrue(url.absoluteString.contains("metadataHeaders=From"))
    }

    func testFullMessageURL() {
        XCTAssertTrue(gmailMessageURL(id: "x", format: .full).absoluteString.contains("format=full"))
    }

    func testProfileAndBatchURLs() {
        XCTAssertTrue(gmailProfileURL().absoluteString.hasSuffix("/profile"))
        XCTAssertTrue(gmailBatchModifyURL().absoluteString.contains("batchModify"))
    }

    func testAuthorizedRequest() {
        let request = authorizedRequest(url: gmailProfileURL(), token: "t", method: "POST", body: Data("{}".utf8))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer t")
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testRequireHTTPData() throws {
        let url = URL(string: "https://example.com")!
        let ok = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!
        XCTAssertEqual(try requireHTTPData((Data(), ok)), Data())
        let bad = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!
        XCTAssertThrowsError(try requireHTTPData((Data(), bad))) { error in
            XCTAssertEqual(error as? MarkSweepError, .httpStatus(403, ""))
        }
    }

    func testRequireHTTPDataIncludesGoogleMessage() {
        let url = URL(string: "https://example.com")!
        let bad = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!
        let body = Data("{\"error\":{\"message\":\"Gmail API has not been used in project 1 before or it is disabled.\"}}".utf8)
        XCTAssertThrowsError(try requireHTTPData((body, bad))) { error in
            guard case let MarkSweepError.httpStatus(status, detail) = error else {
                return XCTFail("wrong error")
            }
            XCTAssertEqual(status, 403)
            XCTAssertTrue(detail.contains("Gmail API has not been used"))
        }
    }

    func testHttpStatusTextForDisabledAPI() {
        let text = httpStatusText(403, detail: "Gmail API has not been used in project X before or it is disabled.")
        XCTAssertEqual(text, "Enable the Gmail API in Google Cloud Console, then Connect again.")
    }

    func testHttpStatusTextForQuota() {
        let text = httpStatusText(403, detail: "Quota exceeded for quota metric 'Total Query Cost'")
        XCTAssertEqual(text, "Gmail rate limit hit. Wait a minute, then Scan again.")
    }

    func testParseList() throws {
        let data = Data("{\"messages\":[{\"id\":\"a\"}],\"nextPageToken\":\"n\"}".utf8)
        let page = try parseGmailMessageList(data: data)
        XCTAssertEqual(page.ids, ["a"])
        XCTAssertEqual(page.nextPageToken, "n")
    }

    func testParseListEmpty() throws {
        let page = try parseGmailMessageList(data: Data("{}".utf8))
        XCTAssertEqual(page.ids, [])
        XCTAssertNil(page.nextPageToken)
    }

    func testParseListBad() {
        XCTAssertThrowsError(try parseGmailMessageList(data: Data("[".utf8)))
    }

    func testParseProfile() throws {
        XCTAssertEqual(try parseGmailProfileEmail(data: Data("{\"emailAddress\":\"a@b.com\"}".utf8)), "a@b.com")
    }

    func testTrashBody() throws {
        let json = try JSONSerialization.jsonObject(with: try gmailTrashBody(ids: ["1"])) as? [String: Any]
        XCTAssertEqual(json?["ids"] as? [String], ["1"])
        XCTAssertEqual(json?["addLabelIds"] as? [String], ["TRASH"])
    }

    func testParseMessageHeadersAndPlain() throws {
        let body = Data("hello world".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let raw = """
        {"id":"m1","labelIds":["INBOX"],"snippet":"sn","sizeEstimate":9,"payload":{\
        "mimeType":"text/plain","headers":[{"name":"From","value":"Ann <a@b.com>"},\
        {"name":"Subject","value":"Hi"},{"name":"Date","value":"Tue, 01 Jan 1970 00:00:01 +0000"},\
        {"name":"List-Unsubscribe","value":"<mailto:x>"}],"body":{"data":"\(body)"}}}
        """
        let features = try parseGmailMessage(data: Data(raw.utf8), now: Date(timeIntervalSince1970: 99))
        XCTAssertEqual(features.id, "m1")
        XCTAssertEqual(features.from, "Ann <a@b.com>")
        XCTAssertEqual(features.subject, "Hi")
        XCTAssertEqual(features.listUnsubscribe, "<mailto:x>")
        XCTAssertEqual(features.bodyText, "hello world")
        XCTAssertEqual(features.date, Date(timeIntervalSince1970: 1))
    }

    func testParseMessageHTMLFallback() throws {
        let html = Data("<p>Hi</p>".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let raw = """
        {"id":"m2","payload":{"mimeType":"multipart/alternative","parts":[\
        {"mimeType":"text/html","body":{"data":"\(html)"}}]}}
        """
        let features = try parseGmailMessage(data: Data(raw.utf8), now: Date(timeIntervalSince1970: 5))
        XCTAssertEqual(features.bodyText, "<p>Hi</p>")
        XCTAssertEqual(features.date, Date(timeIntervalSince1970: 5))
    }

    func testParseMessageBad() {
        XCTAssertThrowsError(try parseGmailMessage(data: Data("[]".utf8), now: Date()))
    }

    func testDecodeGmailBase64Nil() {
        XCTAssertNil(decodeGmailBase64("!!!!"))
    }
}
