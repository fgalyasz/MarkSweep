import Foundation

public enum KeepField: String, Codable, CaseIterable, Identifiable {
    case from
    case to
    case cc
    case recipient
    case subject
    case body

    public var id: String { rawValue }
}

public enum KeepMatch: String, Codable, CaseIterable, Identifiable {
    case contains
    case exact

    public var id: String { rawValue }
}

public struct KeepRule: Equatable, Identifiable, Codable {
    public let id: String
    public var field: KeepField
    public var match: KeepMatch
    public var value: String
    public var keepDays: Int?

    public init(
        id: String,
        field: KeepField,
        match: KeepMatch,
        value: String,
        keepDays: Int? = nil
    ) {
        self.id = id
        self.field = field
        self.match = match
        self.value = value
        self.keepDays = sanitizedKeepDays(keepDays)
    }
}

public func keepFieldTitle(_ field: KeepField) -> String {
    switch field {
    case .from: return "From"
    case .to: return "To"
    case .cc: return "Cc"
    case .recipient: return "To or Cc"
    case .subject: return "Subject"
    case .body: return "Body"
    }
}

public func keepMatchTitle(_ match: KeepMatch) -> String {
    switch match {
    case .contains: return "Contains"
    case .exact: return "Exact"
    }
}

public func sanitizedKeepDays(_ days: Int?) -> Int? {
    guard let days, days > 0 else { return nil }
    return days
}

public func makeKeepRule(
    field: KeepField = .from,
    match: KeepMatch = .contains,
    value: String = "",
    keepDays: Int? = nil
) -> KeepRule {
    KeepRule(id: UUID().uuidString, field: field, match: match, value: value, keepDays: keepDays)
}

public func keepRuleReason(_ rule: KeepRule) -> String {
    guard let days = sanitizedKeepDays(rule.keepDays) else {
        return "Keep rule: \(keepFieldTitle(rule.field))"
    }
    return "Keep rule: \(keepFieldTitle(rule.field)) (\(days)d)"
}

public func keepExpiredReason(_ rule: KeepRule) -> String {
    "Keep ended: \(keepFieldTitle(rule.field))"
}

public func ruleBySettingField(_ rule: KeepRule, _ field: KeepField) -> KeepRule {
    KeepRule(id: rule.id, field: field, match: rule.match, value: rule.value, keepDays: rule.keepDays)
}

public func ruleBySettingMatch(_ rule: KeepRule, _ match: KeepMatch) -> KeepRule {
    KeepRule(id: rule.id, field: rule.field, match: match, value: rule.value, keepDays: rule.keepDays)
}

public func ruleBySettingValue(_ rule: KeepRule, _ value: String) -> KeepRule {
    KeepRule(id: rule.id, field: rule.field, match: rule.match, value: value, keepDays: rule.keepDays)
}

public func ruleBySettingKeepDays(_ rule: KeepRule, _ days: Int?) -> KeepRule {
    KeepRule(id: rule.id, field: rule.field, match: rule.match, value: rule.value, keepDays: days)
}

public func keepDaysText(_ days: Int?) -> String {
    guard let days = sanitizedKeepDays(days) else { return "" }
    return String(days)
}

public func parseKeepDays(_ raw: String) -> Int? {
    sanitizedKeepDays(Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)))
}
