import Foundation

public func keepTextMatches(haystack: String, needle: String, rule: KeepRule) -> Bool {
    let hay = normalizedKeepText(haystack)
    switch rule.match {
    case .contains:
        return hay.contains(needle)
    case .exact:
        return hay == needle || addressExactHit(haystack: haystack, needle: needle, field: rule.field)
    }
}

func addressExactHit(haystack: String, needle: String, field: KeepField) -> Bool {
    guard keepFieldIsAddress(field) else { return false }
    return extractedEmails(haystack).contains { normalizedKeepText($0) == needle }
}

public func extractedEmails(_ raw: String) -> [String] {
    guard let regex = emailRegex() else { return [] }
    let range = NSRange(raw.startIndex..., in: raw)
    return regex.matches(in: raw, range: range).compactMap { emailMatch($0, raw: raw) }
}

func emailRegex() -> NSRegularExpression? {
    let pattern = #"[A-Z0-9._%+\-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
    return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
}

func emailMatch(_ match: NSTextCheckingResult, raw: String) -> String? {
    Range(match.range, in: raw).map { String(raw[$0]) }
}

public func applyKeepRulesToItems(
    _ items: [ReviewItem],
    rules: [KeepRule],
    now: Date = Date()
) -> [ReviewItem] {
    items.map { applyKeepRulesToItem($0, rules: rules, now: now) }
}

public func applyKeepRulesToItem(
    _ item: ReviewItem,
    rules: [KeepRule],
    now: Date = Date()
) -> ReviewItem {
    guard let rule = firstMatchingKeepRule(rules, fields: item.matchFields) else {
        return restoreBaseItem(item)
    }
    if keepRuleIsExpired(keepDays: rule.keepDays, messageDate: item.date, now: now) {
        return expireItem(item, reason: keepExpiredReason(rule))
    }
    return protectItem(item, reason: keepRuleReason(rule))
}

public func protectItem(_ item: ReviewItem, reason: String) -> ReviewItem {
    overlayReviewItem(item, selected: false, verdict: .keep, reason: reason, isProtected: true)
}

public func restoreBaseItem(_ item: ReviewItem) -> ReviewItem {
    let selected = item.isProtected ? defaultSelected(for: item.baseVerdict) : item.selected
    return overlayReviewItem(
        item,
        selected: selected,
        verdict: item.baseVerdict,
        reason: item.baseReason,
        isProtected: false
    )
}
