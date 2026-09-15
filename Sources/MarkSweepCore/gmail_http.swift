import Foundation

public protocol HTTPTransporting {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

public struct URLSessionTransport: HTTPTransporting {
    public init() {}

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

public func authorizedRequest(
    url: URL,
    token: String,
    method: String = "GET",
    body: Data? = nil
) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    if let body {
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    return request
}

public func requireHTTPData(_ pair: (Data, URLResponse)) throws -> Data {
    let response = pair.1 as? HTTPURLResponse
    let status = response?.statusCode ?? 0
    if (200..<300).contains(status) { return pair.0 }
    throw MarkSweepError.httpStatus(status)
}

public enum GmailFormat: String {
    case metadata
    case full
}

public func gmailListURL(query: String, pageToken: String?, maxResults: Int) -> URL {
    var parts = URLComponents(string: "\(gmailAPIRoot)/messages")!
    var items = [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "maxResults", value: String(maxResults))
    ]
    if let pageToken, pageToken.isEmpty == false {
        items.append(URLQueryItem(name: "pageToken", value: pageToken))
    }
    parts.queryItems = items
    return parts.url!
}

public func gmailMessageURL(id: String, format: GmailFormat) -> URL {
    var parts = URLComponents(string: "\(gmailAPIRoot)/messages/\(id)")!
    var items = [URLQueryItem(name: "format", value: format.rawValue)]
    if format == .metadata {
        items.append(contentsOf: metadataHeaderItems())
    }
    parts.queryItems = items
    return parts.url!
}

public func metadataHeaderItems() -> [URLQueryItem] {
    ["From", "Subject", "Date", "List-Unsubscribe"].map {
        URLQueryItem(name: "metadataHeaders", value: $0)
    }
}

public func gmailProfileURL() -> URL {
    URL(string: "\(gmailAPIRoot)/profile")!
}

public func gmailBatchModifyURL() -> URL {
    URL(string: "\(gmailAPIRoot)/messages/batchModify")!
}
