import Foundation

public enum MessageVerdictKind: String, Equatable {
    case keep
    case suspect
    case spamLike
    case large
}

public struct MessageVerdict: Equatable {
    public let kind: MessageVerdictKind
    public let reason: String

    public init(kind: MessageVerdictKind, reason: String) {
        self.kind = kind
        self.reason = reason
    }
}

public func defaultSelected(for kind: MessageVerdictKind) -> Bool {
    kind != .keep
}

public protocol MessageIntelligence {
    func classify(_ features: MessageFeatures) -> MessageVerdict?
}
