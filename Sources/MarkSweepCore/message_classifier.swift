import Foundation

public func classifyMessage(_ features: MessageFeatures, largeBytes: Int) -> MessageVerdict {
    if let labeled = labelVerdict(features) { return labeled }
    if features.listUnsubscribe != nil {
        return MessageVerdict(kind: .spamLike, reason: "Newsletter")
    }
    if features.sizeEstimate >= largeBytes {
        return MessageVerdict(kind: .large, reason: "Large message")
    }
    if let phrase = firstThreatPhrase(in: features) {
        return MessageVerdict(kind: .suspect, reason: phrase)
    }
    return MessageVerdict(kind: .keep, reason: "Looks personal")
}

public func labelVerdict(_ features: MessageFeatures) -> MessageVerdict? {
    if hasLabel(features, "SPAM") {
        return MessageVerdict(kind: .spamLike, reason: "Gmail spam")
    }
    if hasLabel(features, "CATEGORY_PROMOTIONS") {
        return MessageVerdict(kind: .spamLike, reason: "Promotions")
    }
    if hasLabel(features, "CATEGORY_SOCIAL") {
        return MessageVerdict(kind: .spamLike, reason: "Social")
    }
    return nil
}

public func needsBodyFetch(_ features: MessageFeatures, verdict: MessageVerdict) -> Bool {
    verdict.kind == .keep && hasLabel(features, "INBOX")
}

public func refineVerdict(
    _ current: MessageVerdict,
    features: MessageFeatures,
    intelligence: MessageIntelligence
) -> MessageVerdict {
    guard current.kind == .keep else { return current }
    return intelligence.classify(features) ?? current
}

public struct HeuristicIntelligence: MessageIntelligence {
    public init() {}

    public func classify(_ features: MessageFeatures) -> MessageVerdict? {
        guard let phrase = firstThreatPhrase(in: features) else { return nil }
        return MessageVerdict(kind: .suspect, reason: phrase)
    }
}
