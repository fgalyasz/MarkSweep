import Foundation

public struct MessageFeatures: Equatable {
    public let id: String
    public let labelIds: [String]
    public let snippet: String
    public let sizeEstimate: Int
    public let from: String
    public let subject: String
    public let date: Date
    public let listUnsubscribe: String?
    public let bodyText: String?

    public init(
        id: String,
        labelIds: [String],
        snippet: String,
        sizeEstimate: Int,
        from: String,
        subject: String,
        date: Date,
        listUnsubscribe: String?,
        bodyText: String?
    ) {
        self.id = id
        self.labelIds = labelIds
        self.snippet = snippet
        self.sizeEstimate = sizeEstimate
        self.from = from
        self.subject = subject
        self.date = date
        self.listUnsubscribe = listUnsubscribe
        self.bodyText = bodyText
    }
}

public func joinedMessageText(_ features: MessageFeatures) -> String {
    [features.subject, features.snippet, features.bodyText ?? ""].joined(separator: "\n")
}

public func hasLabel(_ features: MessageFeatures, _ label: String) -> Bool {
    features.labelIds.contains(label)
}
