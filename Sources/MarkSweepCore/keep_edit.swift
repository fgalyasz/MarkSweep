import Foundation

public func keepRuleIdentity(_ rule: KeepRule) -> String {
    "\(rule.field.rawValue)|\(rule.match.rawValue)|\(normalizedKeepText(rule.value))"
}

public func keepRulesAreDuplicates(_ left: KeepRule, _ right: KeepRule) -> Bool {
    keepRuleIdentity(left) == keepRuleIdentity(right)
}

public func keepRuleExists(_ rules: [KeepRule], field: KeepField, match: KeepMatch, value: String) -> Bool {
    let probe = KeepRule(id: "", field: field, match: match, value: value)
    return rules.contains { keepRulesAreDuplicates($0, probe) }
}

public func uniqueKeepRules(_ rules: [KeepRule]) -> [KeepRule] {
    var seen = Set<String>()
    return rules.filter { seen.insert(keepRuleIdentity($0)).inserted }
}

public func insertingKeepRule(_ rules: [KeepRule], _ rule: KeepRule) -> [KeepRule] {
    if rules.contains(where: { keepRulesAreDuplicates($0, rule) }) { return rules }
    return rules + [rule]
}

public func updatedKeepRules(_ rules: [KeepRule], replacing rule: KeepRule) -> [KeepRule] {
    if rules.contains(where: { $0.id != rule.id && keepRulesAreDuplicates($0, rule) }) {
        return rules
    }
    return rules.map { $0.id == rule.id ? rule : $0 }
}

public func removingKeepRule(_ rules: [KeepRule], id: String) -> [KeepRule] {
    rules.filter { $0.id != id }
}

public func uniquedKeepSettings(_ settings: MarkSweepSettings) -> MarkSweepSettings {
    let unique = uniqueKeepRules(settings.keepRules)
    guard unique != settings.keepRules else { return settings }
    return settingsByReplacingKeepRules(settings, rules: unique)
}
