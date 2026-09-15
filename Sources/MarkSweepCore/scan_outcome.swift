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
