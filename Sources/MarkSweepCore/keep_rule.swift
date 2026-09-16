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

    public init(id: String, field: KeepField, match: KeepMatch, value: String) {
        self.id = id
        self.field = field
        self.match = match
        self.value = value
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

public func makeKeepRule(field: KeepField = .from, match: KeepMatch = .contains, value: String = "") -> KeepRule {
    KeepRule(id: UUID().uuidString, field: field, match: match, value: value)
}

public func keepRuleReason(_ rule: KeepRule) -> String {
    "Keep rule: \(keepFieldTitle(rule.field))"
}

public func ruleBySettingField(_ rule: KeepRule, _ field: KeepField) -> KeepRule {
    KeepRule(id: rule.id, field: field, match: rule.match, value: rule.value)
}

public func ruleBySettingMatch(_ rule: KeepRule, _ match: KeepMatch) -> KeepRule {
    KeepRule(id: rule.id, field: rule.field, match: match, value: rule.value)
}

public func ruleBySettingValue(_ rule: KeepRule, _ value: String) -> KeepRule {
    KeepRule(id: rule.id, field: rule.field, match: rule.match, value: value)
}
