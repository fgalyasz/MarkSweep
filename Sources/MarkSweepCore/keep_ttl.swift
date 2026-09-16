import Foundation

public let secondsPerKeepDay: TimeInterval = 86_400
public let keepDayPresets = [3, 7, 14, 30]

public func keepRuleIsExpired(keepDays: Int?, messageDate: Date, now: Date) -> Bool {
    guard let days = sanitizedKeepDays(keepDays) else { return false }
    return now.timeIntervalSince(messageDate) >= TimeInterval(days) * secondsPerKeepDay
}

public func expireItem(_ item: ReviewItem, reason: String) -> ReviewItem {
    overlayReviewItem(
        item,
        selected: true,
        verdict: item.baseVerdict,
        reason: reason,
        isProtected: false,
        isKeepExpired: true
    )
}

public func expiredKeepItems(_ items: [ReviewItem]) -> [ReviewItem] {
    items.filter(\.isKeepExpired)
}

public func scanStatusWithExpiry(_ scan: String, expired: Int) -> String {
    if expired == 0 { return scan }
    return "\(scan) Auto-trashed \(expired) expired keep-rule messages."
}
