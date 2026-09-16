import Foundation

public struct MailboxSnapshot: Equatable {
    public let messagesTotal: Int
    public let quota: StorageQuota?
    public let sessionSweptCount: Int
    public let sessionSweptBytes: Int
    public let lifetimeSweptCount: Int
    public let lifetimeSweptBytes: Int

    public init(
        messagesTotal: Int,
        quota: StorageQuota?,
        sessionSweptCount: Int,
        sessionSweptBytes: Int,
        lifetimeSweptCount: Int,
        lifetimeSweptBytes: Int
    ) {
        self.messagesTotal = messagesTotal
        self.quota = quota
        self.sessionSweptCount = sessionSweptCount
        self.sessionSweptBytes = sessionSweptBytes
        self.lifetimeSweptCount = lifetimeSweptCount
        self.lifetimeSweptBytes = lifetimeSweptBytes
    }
}

public func mailboxCountLine(_ snapshot: MailboxSnapshot) -> String {
    formatCount(snapshot.messagesTotal)
}

public func formatCount(_ n: Int) -> String {
    n.formatted()
}

public func mailboxQuotaLine(_ snapshot: MailboxSnapshot) -> String {
    guard let quota = snapshot.quota else { return "Unavailable" }
    return quotaUsageLine(quota)
}

public func quotaUsageLine(_ quota: StorageQuota) -> String {
    guard let free = storageFreeLine(quota) else { return storagePairLine(quota) }
    return "\(storagePairLine(quota)) · \(free)"
}

public func cleanedPairLine(count: Int, bytes: Int) -> String {
    "\(formatCount(count)) · \(formatBytes(bytes))"
}

public func mailboxQuotaNote() -> String {
    "Plan storage is shared with Drive and Photos. Trash still counts until emptied."
}

public func mailboxCleanedSessionLine(_ snapshot: MailboxSnapshot) -> String {
    cleanedPairLine(count: snapshot.sessionSweptCount, bytes: snapshot.sessionSweptBytes)
}

public func mailboxCleanedLifetimeLine(_ snapshot: MailboxSnapshot) -> String {
    cleanedPairLine(count: snapshot.lifetimeSweptCount, bytes: snapshot.lifetimeSweptBytes)
}

public func showingCountLine(visible: Int, total: Int) -> String {
    "Showing \(visible) of \(total)"
}

public func scannedOfMailboxLine(scanned: Int, mailbox: Int) -> String {
    "Scanned \(formatCount(scanned)) of \(formatCount(mailbox))"
}

public func formatBytes64(_ bytes: Int64) -> String {
    formatBytes(Int(clamping: bytes))
}

public func bytesForIds(_ items: [ReviewItem], ids: [String]) -> Int {
    let wanted = Set(ids)
    return items.filter { wanted.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
}
