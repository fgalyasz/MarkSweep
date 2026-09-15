import Foundation

public func gmailScanQueries(largeMegabytes: Int) -> [String] {
    let size = max(1, largeMegabytes)
    return [
        "in:spam",
        "category:promotions",
        "category:social",
        "larger:\(size)M",
        "in:inbox newer_than:365d"
    ]
}

public func largeMegabytes(fromBytes bytes: Int) -> Int {
    max(1, bytes / 1_000_000)
}

public func uniqueIds(_ ids: [String]) -> [String] {
    var seen = Set<String>()
    return ids.filter { seen.insert($0).inserted }
}

public let gmailAPIRoot = "https://gmail.googleapis.com/gmail/v1/users/me"
