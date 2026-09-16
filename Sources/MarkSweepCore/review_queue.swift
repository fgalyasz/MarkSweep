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
    public let date: Date
    public let sizeBytes: Int
    public let preview: String
    public let isSpamFolder: Bool
    public let isProtected: Bool
    public let baseVerdict: MessageVerdictKind
    public let baseReason: String
    public let matchFields: MessageMatchFields
    public let isKeepExpired: Bool

    public var subject: String { matchFields.subject }
    public var sender: String { matchFields.from }

    public init(
        id: String,
        selected: Bool,
        verdict: MessageVerdictKind,
        reason: String,
        date: Date,
        sizeBytes: Int,
        preview: String,
        isSpamFolder: Bool,
        isProtected: Bool,
        baseVerdict: MessageVerdictKind,
        baseReason: String,
        matchFields: MessageMatchFields,
        isKeepExpired: Bool = false
    ) {
        self.id = id
        self.selected = selected
        self.verdict = verdict
        self.reason = reason
        self.date = date
        self.sizeBytes = sizeBytes
        self.preview = preview
        self.isSpamFolder = isSpamFolder
        self.isProtected = isProtected
        self.baseVerdict = baseVerdict
        self.baseReason = baseReason
        self.matchFields = matchFields
        self.isKeepExpired = isKeepExpired
    }
}

public func reviewItem(from features: MessageFeatures, verdict: MessageVerdict) -> ReviewItem {
    ReviewItem(
        id: features.id,
        selected: defaultSelected(for: verdict.kind),
        verdict: verdict.kind,
        reason: verdict.reason,
        date: features.date,
        sizeBytes: features.sizeEstimate,
        preview: previewForMessage(features),
        isSpamFolder: hasLabel(features, "SPAM"),
        isProtected: false,
        baseVerdict: verdict.kind,
        baseReason: verdict.reason,
        matchFields: matchFields(from: features),
        isKeepExpired: false
    )
}

public func overlayReviewItem(
    _ item: ReviewItem,
    selected: Bool,
    verdict: MessageVerdictKind,
    reason: String,
    isProtected: Bool,
    isKeepExpired: Bool = false
) -> ReviewItem {
    ReviewItem(
        id: item.id,
        selected: selected,
        verdict: verdict,
        reason: reason,
        date: item.date,
        sizeBytes: item.sizeBytes,
        preview: item.preview,
        isSpamFolder: item.isSpamFolder,
        isProtected: isProtected,
        baseVerdict: item.baseVerdict,
        baseReason: item.baseReason,
        matchFields: item.matchFields,
        isKeepExpired: isKeepExpired
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
        toggleOneSelection(item, id: id)
    }
}

func toggleOneSelection(_ item: ReviewItem, id: String) -> ReviewItem {
    guard item.id == id, item.isProtected == false else { return item }
    var copy = item
    copy.selected.toggle()
    return copy
}

public func setVisibleSelection(_ items: [ReviewItem], filter: ReviewFilter, selected: Bool) -> [ReviewItem] {
    items.map { item in
        setOneVisibleSelection(item, filter: filter, selected: selected)
    }
}

func setOneVisibleSelection(_ item: ReviewItem, filter: ReviewFilter, selected: Bool) -> ReviewItem {
    guard itemMatchesFilter(item, filter: filter) else { return item }
    if item.isProtected {
        return overlayReviewItem(
            item,
            selected: false,
            verdict: item.verdict,
            reason: item.reason,
            isProtected: true,
            isKeepExpired: item.isKeepExpired
        )
    }
    var copy = item
    copy.selected = selected
    return copy
}

public func selectedItems(_ items: [ReviewItem]) -> [ReviewItem] {
    items.filter(\.selected)
}

public func sweepableItems(_ items: [ReviewItem]) -> [ReviewItem] {
    selectedItems(items).filter { $0.isProtected == false }
}
