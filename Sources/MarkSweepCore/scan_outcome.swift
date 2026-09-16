import Foundation

public struct ScanOutcome: Equatable {
    public let items: [ReviewItem]
    public let stoppedEarly: Bool

    public init(items: [ReviewItem], stoppedEarly: Bool) {
        self.items = items
        self.stoppedEarly = stoppedEarly
    }
}

public func scanStatusText(_ outcome: ScanOutcome) -> String {
    if outcome.stoppedEarly {
        return "Scanned \(outcome.items.count) messages, then Gmail asked us to slow down. Wait a minute and Scan again."
    }
    return "Scanned \(outcome.items.count) messages."
}

public func scanCoverageStatus(scanned: Int, mailbox: Int, hasMore: Bool, stoppedEarly: Bool) -> String {
    if stoppedEarly {
        return "Scanned \(scanned) messages, then Gmail asked us to slow down. Wait a minute and Scan again."
    }
    if hasMore {
        return "Reviewed \(scanned) of \(mailbox) mailbox messages. Scan again for older mail."
    }
    return "Reviewed \(scanned) of \(mailbox) mailbox messages. Caught up (Sent, Drafts, and Trash skipped)."
}
