import Foundation

public let harassmentPhrases = [
    "kill yourself",
    "kys",
    "i will find you",
    "watch your back",
    "you will regret this",
    "i know where you live"
]

public let phishingPhrases = [
    "verify your account now",
    "confirm your password",
    "your mailbox is full",
    "account has been suspended",
    "click here to unlock",
    "urgent wire transfer",
    "pay with gift cards"
]

public func matchedPhrase(in text: String, phrases: [String]) -> String? {
    let hay = text.lowercased()
    return phrases.first(where: { hay.contains($0) })
}

public func firstThreatPhrase(in features: MessageFeatures) -> String? {
    let text = joinedMessageText(features)
    return matchedPhrase(in: text, phrases: harassmentPhrases)
        ?? matchedPhrase(in: text, phrases: phishingPhrases)
}
