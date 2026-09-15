import Foundation
import XCTest
@testable import MarkSweepCore

final class ScriptedTransport: HTTPTransporting {
    var queue: [(Int, Data)]
    private(set) var requests: [URLRequest] = []

    init(queue: [(Int, Data)]) {
        self.queue = queue
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard queue.isEmpty == false else { throw MarkSweepError.decode }
        let next = queue.removeFirst()
        let url = request.url ?? URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: next.0, httpVersion: nil, headerFields: nil)!
        return (next.1, response)
    }
}

func jsonData(_ object: Any) throws -> Data {
    try JSONSerialization.data(withJSONObject: object)
}

final class GmailClientTests: XCTestCase {
    func testProfile() async throws {
        let transport = ScriptedTransport(queue: [(200, try jsonData(["emailAddress": "a@b.com"]))])
        let client = GmailClient(transport: transport, accessToken: "t", now: Date(timeIntervalSince1970: 0))
        let email = try await client.profileEmail()
        XCTAssertEqual(email, "a@b.com")
        XCTAssertEqual(transport.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer t")
    }

    func testListPagesUntilCap() async throws {
        let page1 = try jsonData(["messages": [["id": "a"], ["id": "b"]], "nextPageToken": "n"])
        let page2 = try jsonData(["messages": [["id": "c"]]])
        let transport = ScriptedTransport(queue: [(200, page1), (200, page2)])
        let client = GmailClient(transport: transport, accessToken: "t")
        let ids = try await listIds(client: client, query: "in:spam", cap: 2)
        XCTAssertEqual(ids, ["a", "b"])
        XCTAssertEqual(transport.requests.count, 1)
    }

    func testCollectScanIdsUnique() async throws {
        let page = try jsonData(["messages": [["id": "a"]]])
        var queue: [(Int, Data)] = []
        for _ in 0..<5 { queue.append((200, page)) }
        let transport = ScriptedTransport(queue: queue)
        let client = GmailClient(transport: transport, accessToken: "t")
        let ids = try await collectScanIds(client: client, largeBytes: 5_000_000, cap: 10)
        XCTAssertEqual(ids, ["a"])
        XCTAssertEqual(transport.requests.count, 5)
    }

    func testScanMetadataSpamDoesNotFetchBody() async throws {
        let message = try jsonData([
            "id": "m",
            "labelIds": ["SPAM"],
            "snippet": "x",
            "sizeEstimate": 12,
            "payload": ["headers": [["name": "Subject", "value": "Sale"]]]
        ])
        let transport = ScriptedTransport(queue: [(200, message)])
        let client = GmailClient(transport: transport, accessToken: "t")
        let item = try await scanOneMessage(client: client, id: "m", largeBytes: 5_000_000)
        XCTAssertEqual(item.verdict, .spamLike)
        XCTAssertEqual(transport.requests.count, 1)
        XCTAssertTrue(transport.requests[0].url?.absoluteString.contains("format=metadata") == true)
    }

    func testScanInboxKeepFetchesFull() async throws {
        let meta = try jsonData([
            "id": "m",
            "labelIds": ["INBOX"],
            "snippet": "hello",
            "sizeEstimate": 12,
            "payload": ["headers": [["name": "Subject", "value": "Hi"]]]
        ])
        let full = try jsonData([
            "id": "m",
            "labelIds": ["INBOX"],
            "snippet": "hello",
            "sizeEstimate": 12,
            "payload": [
                "mimeType": "text/plain",
                "headers": [["name": "Subject", "value": "Hi"]],
                "body": ["data": Data("verify your account now".utf8).base64EncodedString()]
            ]
        ])
        let transport = ScriptedTransport(queue: [(200, meta), (200, full)])
        let client = GmailClient(transport: transport, accessToken: "t")
        let item = try await scanOneMessage(client: client, id: "m", largeBytes: 5_000_000)
        XCTAssertEqual(item.verdict, .suspect)
        XCTAssertEqual(transport.requests.count, 2)
        XCTAssertTrue(transport.requests[1].url?.absoluteString.contains("format=full") == true)
    }

    func testTrashChunksReportFailure() async throws {
        let transport = ScriptedTransport(queue: [(200, Data()), (500, Data())])
        let client = GmailClient(transport: transport, accessToken: "t")
        let ids = (0..<1001).map { String($0) }
        let result = await trashSelected(client: client, ids: ids)
        XCTAssertEqual(result.trashedIds.count, 1000)
        XCTAssertEqual(result.failedIds.count, 1)
    }

    func testHTTPError() async {
        let transport = ScriptedTransport(queue: [(401, Data())])
        let client = GmailClient(transport: transport, accessToken: "t")
        do {
            _ = try await client.profileEmail()
            XCTFail("expected throw")
        } catch let error as MarkSweepError {
            XCTAssertEqual(error, .httpStatus(401, ""))
        } catch {
            XCTFail("wrong error")
        }
    }

    func testScanMessages() async throws {
        let message = try jsonData([
            "id": "m",
            "labelIds": ["CATEGORY_SOCIAL"],
            "snippet": "x",
            "sizeEstimate": 1,
            "payload": ["headers": [["name": "Subject", "value": "N"]]]
        ])
        let transport = ScriptedTransport(queue: [(200, message)])
        let client = GmailClient(transport: transport, accessToken: "t")
        let items = try await scanMessages(client: client, ids: ["m"], largeBytes: 5_000_000)
        XCTAssertEqual(items.first?.verdict, .spamLike)
    }
}

final class OAuthSessionTests: XCTestCase {
    func testEnsureTokenSkipsRefresh() async throws {
        let token = OAuthToken(accessToken: "a", refreshToken: "r", expiry: Date().addingTimeInterval(3600))
        let store = MemoryTokenStore(token: token)
        let transport = ScriptedTransport(queue: [])
        let config = GoogleOAuthConfig(clientID: "id", clientSecret: nil)
        let loaded = try await ensureAccessToken(store: store, transport: transport, config: config, now: Date())
        XCTAssertEqual(loaded.accessToken, "a")
        XCTAssertEqual(transport.requests.count, 0)
    }

    func testRefreshAndStore() async throws {
        let old = OAuthToken(accessToken: "old", refreshToken: "r", expiry: Date(timeIntervalSince1970: 1))
        let store = MemoryTokenStore(token: old)
        let body = try jsonData(["access_token": "new", "expires_in": 10])
        let transport = ScriptedTransport(queue: [(200, body)])
        let config = GoogleOAuthConfig(clientID: "id", clientSecret: nil)
        let now = Date(timeIntervalSince1970: 100)
        let next = try await ensureAccessToken(store: store, transport: transport, config: config, now: now)
        XCTAssertEqual(next.accessToken, "new")
        XCTAssertEqual(next.refreshToken, "r")
        XCTAssertEqual(try store.load()?.accessToken, "new")
    }

    func testRefreshWithoutRefreshToken() async {
        let old = OAuthToken(accessToken: "old", refreshToken: nil, expiry: Date(timeIntervalSince1970: 1))
        let store = MemoryTokenStore(token: old)
        let transport = ScriptedTransport(queue: [])
        let config = GoogleOAuthConfig(clientID: "id", clientSecret: nil)
        do {
            _ = try await ensureAccessToken(
                store: store,
                transport: transport,
                config: config,
                now: Date(timeIntervalSince1970: 100)
            )
            XCTFail("expected throw")
        } catch let error as MarkSweepError {
            XCTAssertEqual(error, .tokenMissing)
        } catch {
            XCTFail("wrong error")
        }
    }

    func testMissingStoredToken() async {
        let store = MemoryTokenStore()
        do {
            _ = try await ensureAccessToken(
                store: store,
                transport: ScriptedTransport(queue: []),
                config: GoogleOAuthConfig(clientID: "id", clientSecret: nil),
                now: Date()
            )
            XCTFail("expected throw")
        } catch let error as MarkSweepError {
            XCTAssertEqual(error, .tokenMissing)
        } catch {
            XCTFail("wrong error")
        }
    }

    func testExchangeCodeAndStore() async throws {
        let store = MemoryTokenStore()
        let body = try jsonData(["access_token": "a", "refresh_token": "r", "expires_in": 5])
        let transport = ScriptedTransport(queue: [(200, body)])
        let config = GoogleOAuthConfig(clientID: "id", clientSecret: "s")
        let now = Date(timeIntervalSince1970: 0)
        let token = try await exchangeCodeAndStore(
            code: "c",
            verifier: "v",
            redirectURI: "http://127.0.0.1:9/",
            store: store,
            transport: transport,
            config: config,
            now: now
        )
        XCTAssertEqual(token.refreshToken, "r")
        XCTAssertEqual(try store.load()?.accessToken, "a")
        XCTAssertEqual(transport.requests.first?.httpMethod, "POST")
    }
}
