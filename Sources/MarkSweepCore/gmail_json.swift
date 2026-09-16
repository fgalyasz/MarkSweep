import Foundation

struct GmailHeaderJSON: Decodable {
    let name: String?
    let value: String?
}

struct GmailBodyJSON: Decodable {
    let data: String?
}

struct GmailPayloadJSON: Decodable {
    let mimeType: String?
    let headers: [GmailHeaderJSON]?
    let body: GmailBodyJSON?
    let parts: [GmailPayloadJSON]?
}

struct GmailMessageJSON: Decodable {
    let id: String
    let threadId: String?
    let labelIds: [String]?
    let snippet: String?
    let sizeEstimate: Int?
    let payload: GmailPayloadJSON?
}

struct GmailListJSON: Decodable {
    let messages: [GmailListItemJSON]?
    let nextPageToken: String?
}

struct GmailListItemJSON: Decodable {
    let id: String
}

struct GmailProfileJSON: Decodable {
    let emailAddress: String
    let messagesTotal: Int?
}

func headerValue(_ headers: [GmailHeaderJSON]?, name: String) -> String? {
    let target = name.lowercased()
    return headers?.first(where: { ($0.name ?? "").lowercased() == target })?.value
}

public func decodeGmailBase64(_ value: String) -> String? {
    var padded = value.replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let remainder = padded.count % 4
    if remainder > 0 { padded += String(repeating: "=", count: 4 - remainder) }
    guard let data = Data(base64Encoded: padded) else { return nil }
    return String(data: data, encoding: .utf8)
}

func plainTextFromPayload(_ payload: GmailPayloadJSON?) -> String? {
    guard let root = payload else { return nil }
    var stack = [root]
    while stack.isEmpty == false {
        let current = stack.removeLast()
        if let text = plainPart(current) { return text }
        stack.append(contentsOf: current.parts ?? [])
    }
    return htmlPartFromPayload(root)
}

func plainPart(_ payload: GmailPayloadJSON) -> String? {
    guard payload.mimeType == "text/plain" else { return nil }
    guard let data = payload.body?.data else { return nil }
    return decodeGmailBase64(data)
}

func htmlPartFromPayload(_ payload: GmailPayloadJSON) -> String? {
    var stack = [payload]
    while stack.isEmpty == false {
        let current = stack.removeLast()
        if current.mimeType == "text/html", let data = current.body?.data {
            return decodeGmailBase64(data)
        }
        stack.append(contentsOf: current.parts ?? [])
    }
    return nil
}

public func parseGmailDate(_ value: String?, now: Date) -> Date {
    guard let value, value.isEmpty == false else { return now }
    let rfc = DateFormatter()
    rfc.locale = Locale(identifier: "en_US_POSIX")
    rfc.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
    return rfc.date(from: value) ?? now
}

func featuresFromJSON(_ json: GmailMessageJSON, now: Date) -> MessageFeatures {
    let headers = json.payload?.headers
    return MessageFeatures(
        id: json.id,
        labelIds: json.labelIds ?? [],
        snippet: json.snippet ?? "",
        sizeEstimate: json.sizeEstimate ?? 0,
        from: headerValue(headers, name: "From") ?? "",
        subject: headerValue(headers, name: "Subject") ?? "",
        date: parseGmailDate(headerValue(headers, name: "Date"), now: now),
        listUnsubscribe: headerValue(headers, name: "List-Unsubscribe"),
        bodyText: plainTextFromPayload(json.payload)
    )
}

public func parseGmailMessage(data: Data, now: Date) throws -> MessageFeatures {
    guard let json = try? JSONDecoder().decode(GmailMessageJSON.self, from: data) else {
        throw MarkSweepError.decode
    }
    return featuresFromJSON(json, now: now)
}

public func parseGmailMessageList(data: Data) throws -> (ids: [String], nextPageToken: String?) {
    guard let json = try? JSONDecoder().decode(GmailListJSON.self, from: data) else {
        throw MarkSweepError.decode
    }
    let ids = (json.messages ?? []).map(\.id)
    return (ids, json.nextPageToken)
}

public func parseGmailProfile(data: Data) throws -> GmailProfile {
    guard let json = try? JSONDecoder().decode(GmailProfileJSON.self, from: data) else {
        throw MarkSweepError.decode
    }
    return GmailProfile(email: json.emailAddress, messagesTotal: json.messagesTotal ?? 0)
}

public func parseGmailProfileEmail(data: Data) throws -> String {
    try parseGmailProfile(data: data).email
}

public func gmailTrashBody(ids: [String]) throws -> Data {
    try JSONSerialization.data(withJSONObject: ["ids": ids, "addLabelIds": ["TRASH"]])
}
