import Foundation

public struct MessageMatchFields: Equatable {
    public let from: String
    public let to: String
    public let cc: String
    public let subject: String
    public let body: String

    public init(from: String, to: String, cc: String, subject: String, body: String) {
        self.from = from
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
    }
}

public func matchFields(from features: MessageFeatures) -> MessageMatchFields {
    MessageMatchFields(
        from: features.from,
        to: features.to,
        cc: features.cc,
        subject: features.subject,
        body: [features.snippet, features.bodyText ?? ""].joined(separator: "\n")
    )
}

public func emptyMatchFields() -> MessageMatchFields {
    MessageMatchFields(from: "", to: "", cc: "", subject: "", body: "")
}

public func keepFieldHaystack(_ fields: MessageMatchFields, field: KeepField) -> String {
    switch field {
    case .from: return fields.from
    case .to: return fields.to
    case .cc: return fields.cc
    case .recipient: return [fields.to, fields.cc].filter { $0.isEmpty == false }.joined(separator: ", ")
    case .subject: return fields.subject
    case .body: return fields.body
    }
}

public func keepFieldIsAddress(_ field: KeepField) -> Bool {
    field != .subject && field != .body
}

public func normalizedKeepText(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

public func keepRuleMatches(_ rule: KeepRule, fields: MessageMatchFields) -> Bool {
    let needle = normalizedKeepText(rule.value)
    guard needle.isEmpty == false else { return false }
    return keepTextMatches(haystack: keepFieldHaystack(fields, field: rule.field), needle: needle, rule: rule)
}

public func firstMatchingKeepRule(_ rules: [KeepRule], fields: MessageMatchFields) -> KeepRule? {
    rules.first { keepRuleMatches($0, fields: fields) }
}
