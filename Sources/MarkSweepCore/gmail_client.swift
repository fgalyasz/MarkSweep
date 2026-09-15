import Foundation

public struct GmailClient {
    public let transport: HTTPTransporting
    public let accessToken: String
    public let now: Date

    public init(transport: HTTPTransporting, accessToken: String, now: Date = Date()) {
        self.transport = transport
        self.accessToken = accessToken
        self.now = now
    }

    public func get(url: URL) async throws -> Data {
        let request = authorizedRequest(url: url, token: accessToken)
        return try requireHTTPData(try await transport.data(for: request))
    }

    public func post(url: URL, body: Data) async throws -> Data {
        let request = authorizedRequest(url: url, token: accessToken, method: "POST", body: body)
        return try requireHTTPData(try await transport.data(for: request))
    }

    public func profileEmail() async throws -> String {
        try parseGmailProfileEmail(data: try await get(url: gmailProfileURL()))
    }

    public func message(id: String, format: GmailFormat) async throws -> MessageFeatures {
        let data = try await get(url: gmailMessageURL(id: id, format: format))
        return try parseGmailMessage(data: data, now: now)
    }

    public func listPage(query: String, pageToken: String?, maxResults: Int) async throws -> (ids: [String], next: String?) {
        let url = gmailListURL(query: query, pageToken: pageToken, maxResults: maxResults)
        let page = try parseGmailMessageList(data: try await get(url: url))
        return (page.ids, page.nextPageToken)
    }

    public func trash(ids: [String]) async throws {
        let body = try gmailTrashBody(ids: ids)
        _ = try await post(url: gmailBatchModifyURL(), body: body)
    }
}

public func listIds(client: GmailClient, query: String, cap: Int) async throws -> [String] {
    var all: [String] = []
    var token: String?
    while all.count < cap {
        let pageSize = min(100, cap - all.count)
        let page = try await client.listPage(query: query, pageToken: token, maxResults: pageSize)
        all.append(contentsOf: page.ids)
        if page.next == nil || page.ids.isEmpty { break }
        token = page.next
    }
    return Array(all.prefix(cap))
}

public func collectScanIds(client: GmailClient, largeBytes: Int, cap: Int) async throws -> [String] {
    let queries = gmailScanQueries(largeMegabytes: largeMegabytes(fromBytes: largeBytes))
    var all: [String] = []
    for query in queries {
        all.append(contentsOf: try await listIds(client: client, query: query, cap: cap))
    }
    return uniqueIds(all)
}

public func scanOneMessage(client: GmailClient, id: String, largeBytes: Int) async throws -> ReviewItem {
    let meta = try await client.message(id: id, format: .metadata)
    let first = classifyMessage(meta, largeBytes: largeBytes)
    if needsBodyFetch(meta, verdict: first) == false {
        return reviewItem(from: meta, verdict: first)
    }
    return try await scanInboxKeep(client: client, id: id, largeBytes: largeBytes)
}

public func scanInboxKeep(client: GmailClient, id: String, largeBytes: Int) async throws -> ReviewItem {
    let full = try await client.message(id: id, format: .full)
    let intelligence = HeuristicIntelligence()
    let base = classifyMessage(full, largeBytes: largeBytes)
    let verdict = refineVerdict(base, features: full, intelligence: intelligence)
    return reviewItem(from: full, verdict: verdict)
}

public func scanMessages(client: GmailClient, ids: [String], largeBytes: Int) async throws -> [ReviewItem] {
    var items: [ReviewItem] = []
    for id in ids {
        items.append(try await scanOneMessage(client: client, id: id, largeBytes: largeBytes))
    }
    return items
}

public func trashSelected(client: GmailClient, ids: [String]) async -> SweepResult {
    var trashed: [String] = []
    var failed: [String] = []
    for chunk in chunkIds(ids) {
        await appendTrashChunk(client: client, chunk: chunk, trashed: &trashed, failed: &failed)
    }
    return SweepResult(trashedIds: trashed, failedIds: failed)
}

func appendTrashChunk(
    client: GmailClient,
    chunk: [String],
    trashed: inout [String],
    failed: inout [String]
) async {
    do {
        try await client.trash(ids: chunk)
        trashed.append(contentsOf: chunk)
    } catch {
        failed.append(contentsOf: chunk)
    }
}
