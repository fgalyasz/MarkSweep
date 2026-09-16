import Foundation

public enum ReviewFilter: String, CaseIterable, Identifiable {
    case all
    case suspect
    case large
    case spamFolder

    public var id: String { rawValue }
}

public func reviewFilterTitle(_ filter: ReviewFilter) -> String {
    switch filter {
    case .all: return "All"
    case .suspect: return "Suspect"
    case .large: return "Large"
    case .spamFolder: return "Spam folder"
    }
}

public struct ReviewItem: Equatable, Identifiable {
    public let id: String
    public var selected: Bool
    public let verdict: MessageVerdictKind
    public let reason: String
    public let subject: String
    public let sender: String
    public let date: Date
    public let sizeBytes: Int
    public let preview: String
    public let isSpamFolder: Bool

    public init(
        id: String,
        selected: Bool,
        verdict: MessageVerdictKind,
        reason: String,
        subject: String,
        sender: String,
        date: Date,
        sizeBytes: Int,
        preview: String,
        isSpamFolder: Bool
    ) {
        self.id = id
        self.selected = selected
        self.verdict = verdict
        self.reason = reason
        self.subject = subject
        self.sender = sender
        self.date = date
        self.sizeBytes = sizeBytes
        self.preview = preview
        self.isSpamFolder = isSpamFolder
    }
}

public func reviewItem(from features: MessageFeatures, verdict: MessageVerdict) -> ReviewItem {
    ReviewItem(
        id: features.id,
        selected: defaultSelected(for: verdict.kind),
        verdict: verdict.kind,
        reason: verdict.reason,
        subject: features.subject,
        sender: features.from,
        date: features.date,
        sizeBytes: features.sizeEstimate,
        preview: previewForMessage(features),
        isSpamFolder: hasLabel(features, "SPAM")
    )
}

public func itemMatchesFilter(_ item: ReviewItem, filter: ReviewFilter) -> Bool {
    switch filter {
    case .all: return true
    case .suspect: return item.verdict == .suspect
    case .large: return item.verdict == .large
    case .spamFolder: return item.isSpamFolder
    }
}

public func filteredItems(_ items: [ReviewItem], filter: ReviewFilter) -> [ReviewItem] {
    items.filter { itemMatchesFilter($0, filter: filter) }
}

public func matchingCount(_ items: [ReviewItem], filter: ReviewFilter) -> Int {
    filteredItems(items, filter: filter).count
}

public func toggleSelection(_ items: [ReviewItem], id: String) -> [ReviewItem] {
    items.map { item in
        if item.id != id { return item }
        var copy = item
        copy.selected.toggle()
        return copy
    }
}

public func setVisibleSelection(_ items: [ReviewItem], filter: ReviewFilter, selected: Bool) -> [ReviewItem] {
    items.map { item in
        if itemMatchesFilter(item, filter: filter) == false { return item }
        var copy = item
        copy.selected = selected
        return copy
    }
}

public func selectedItems(_ items: [ReviewItem]) -> [ReviewItem] {
    items.filter(\.selected)
}
