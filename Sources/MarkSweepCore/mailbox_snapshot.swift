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
    "\(snapshot.messagesTotal) messages in mailbox"
}

public func mailboxQuotaLine(_ snapshot: MailboxSnapshot) -> String {
    guard let quota = snapshot.quota else { return "Google storage unavailable" }
    return quotaUsageLine(quota)
}

public func quotaUsageLine(_ quota: StorageQuota) -> String {
    let used = formatBytes64(quota.usage)
    guard let limit = quota.limit, let left = storageRemaining(quota) else {
        return "\(used) used (no plan limit reported)"
    }
    return "\(used) of \(formatBytes64(limit)) used · \(formatBytes64(left)) free"
}

public func mailboxQuotaNote() -> String {
    "Plan storage is shared with Drive and Photos. Trash still counts until emptied."
}

public func mailboxCleanedSessionLine(_ snapshot: MailboxSnapshot) -> String {
    "This session: \(snapshot.sessionSweptCount) · \(formatBytes(snapshot.sessionSweptBytes))"
}

public func mailboxCleanedLifetimeLine(_ snapshot: MailboxSnapshot) -> String {
    "With MarkSweep: \(snapshot.lifetimeSweptCount) · \(formatBytes(snapshot.lifetimeSweptBytes))"
}

public func showingCountLine(visible: Int, total: Int) -> String {
    "Showing \(visible) of \(total)"
}

public func formatBytes64(_ bytes: Int64) -> String {
    formatBytes(Int(clamping: bytes))
}

public func bytesForIds(_ items: [ReviewItem], ids: [String]) -> Int {
    let wanted = Set(ids)
    return items.filter { wanted.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
}
