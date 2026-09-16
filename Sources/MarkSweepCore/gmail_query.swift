import Foundation

public func gmailCleanableQuery() -> String {
    "-in:sent -in:drafts -in:trash -in:chats"
}

public func gmailScanQueries(largeMegabytes: Int) -> [String] {
    let size = max(1, largeMegabytes)
    return [
        "in:spam",
        "category:promotions",
        "category:social",
        "category:updates",
        "category:forums",
        "larger:\(size)M",
        "in:inbox"
    ]
}

public func largeMegabytes(fromBytes bytes: Int) -> Int {
    max(1, bytes / 1_000_000)
}

public func uniqueIds(_ ids: [String]) -> [String] {
    var seen = Set<String>()
    return ids.filter { seen.insert($0).inserted }
}

public func unseenScanIds(_ ids: [String], have: Set<String>) -> [String] {
    ids.filter { have.contains($0) == false }
}

public func mergingReviewItems(_ current: [ReviewItem], incoming: [ReviewItem]) -> [ReviewItem] {
    let have = Set(current.map(\.id))
    return current + incoming.filter { have.contains($0.id) == false }
}

public let gmailAPIRoot = "https://gmail.googleapis.com/gmail/v1/users/me"
