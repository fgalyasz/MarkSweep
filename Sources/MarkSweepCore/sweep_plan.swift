import Foundation

public struct SweepPlan: Equatable {
    public let ids: [String]
    public let count: Int
    public let bytes: Int

    public init(ids: [String], count: Int, bytes: Int) {
        self.ids = ids
        self.count = count
        self.bytes = bytes
    }
}

public func sweepPlan(from items: [ReviewItem]) -> SweepPlan {
    let chosen = sweepableItems(items)
    let bytes = chosen.reduce(0) { $0 + $1.sizeBytes }
    return SweepPlan(ids: chosen.map(\.id), count: chosen.count, bytes: bytes)
}

public func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}

public struct SweepResult: Equatable {
    public let trashedIds: [String]
    public let failedIds: [String]

    public init(trashedIds: [String], failedIds: [String]) {
        self.trashedIds = trashedIds
        self.failedIds = failedIds
    }
}

public func sweepSummary(_ plan: SweepPlan, result: SweepResult) -> String {
    let ok = result.trashedIds.count
    let fail = result.failedIds.count
    return "Moved \(ok) of \(plan.count) to Trash (\(formatBytes(plan.bytes))). Failed: \(fail)."
}

public func removeTrashed(_ items: [ReviewItem], trashedIds: [String]) -> [ReviewItem] {
    let gone = Set(trashedIds)
    return items.filter { gone.contains($0.id) == false }
}

public let gmailTrashChunkSize = 1000

public func chunkIds(_ ids: [String], size: Int = gmailTrashChunkSize) -> [[String]] {
    guard size > 0 else { return [] }
    var chunks: [[String]] = []
    var index = 0
    while index < ids.count {
        let end = min(index + size, ids.count)
        chunks.append(Array(ids[index..<end]))
        index = end
    }
    return chunks
}
