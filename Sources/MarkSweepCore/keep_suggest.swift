import Foundation

public struct KeepRuleSuggestion: Equatable, Identifiable {
    public let field: KeepField
    public let match: KeepMatch
    public let value: String

    public var id: String { field.rawValue }

    public init(field: KeepField, match: KeepMatch, value: String) {
        self.field = field
        self.match = match
        self.value = value
    }
}

public func keepRuleSuggestions(from fields: MessageMatchFields) -> [KeepRuleSuggestion] {
    KeepField.allCases.compactMap { keepRuleSuggestion(field: $0, fields: fields) }
}

public func keepRuleSuggestion(field: KeepField, fields: MessageMatchFields) -> KeepRuleSuggestion? {
    let value = keepRuleValue(from: fields, field: field)
    guard value.isEmpty == false else { return nil }
    return KeepRuleSuggestion(field: field, match: keepSuggestionMatch(field), value: value)
}

public func keepSuggestionMatch(_ field: KeepField) -> KeepMatch {
    field == .body ? .contains : .exact
}

public func keepRuleValue(from fields: MessageMatchFields, field: KeepField) -> String {
    switch field {
    case .from, .to, .cc, .recipient:
        return firstKeepAddress(keepFieldHaystack(fields, field: field))
    case .subject:
        return fields.subject.trimmingCharacters(in: .whitespacesAndNewlines)
    case .body:
        return bodyKeepSeed(fields.body)
    }
}

public func firstKeepAddress(_ raw: String) -> String {
    extractedEmails(raw).first ?? raw.trimmingCharacters(in: .whitespacesAndNewlines)
}

public func bodyKeepSeed(_ raw: String) -> String {
    let line = raw.split(whereSeparator: \.isNewline).first.map(String.init) ?? raw
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.count <= 80 { return trimmed }
    return String(trimmed.prefix(80))
}

public func keepSuggestionTitle(_ suggestion: KeepRuleSuggestion) -> String {
    "\(keepFieldTitle(suggestion.field)): \(suggestion.value)"
}

public func makeKeepRule(from suggestion: KeepRuleSuggestion) -> KeepRule {
    makeKeepRule(field: suggestion.field, match: suggestion.match, value: suggestion.value)
}
