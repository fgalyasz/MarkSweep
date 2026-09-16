import Foundation

public struct GmailProfile: Equatable {
    public let email: String
    public let messagesTotal: Int

    public init(email: String, messagesTotal: Int) {
        self.email = email
        self.messagesTotal = messagesTotal
    }
}

public struct StorageQuota: Equatable {
    public let usage: Int64
    public let limit: Int64?

    public init(usage: Int64, limit: Int64?) {
        self.usage = usage
        self.limit = limit
    }
}

public func storageRemaining(_ quota: StorageQuota) -> Int64? {
    guard let limit = quota.limit else { return nil }
    return max(0, limit - quota.usage)
}

public func quotaFillRatio(_ quota: StorageQuota) -> Double? {
    guard let limit = quota.limit, limit > 0 else { return nil }
    let raw = Double(quota.usage) / Double(limit)
    return min(1, max(0, raw))
}

public func storagePairLine(_ quota: StorageQuota) -> String {
    let used = formatBytes64(quota.usage)
    guard let limit = quota.limit else { return "\(used) used" }
    return "\(used) / \(formatBytes64(limit))"
}

public func storageFreeLine(_ quota: StorageQuota) -> String? {
    guard let left = storageRemaining(quota) else { return nil }
    return "\(formatBytes64(left)) free"
}

struct DriveAboutJSON: Decodable {
    let storageQuota: DriveQuotaJSON?
}

struct DriveQuotaJSON: Decodable {
    let limit: String?
    let usage: String?
}

public func int64Field(_ raw: String?) -> Int64? {
    guard let raw, raw.isEmpty == false else { return nil }
    return Int64(raw)
}

public func parseDriveQuota(data: Data) throws -> StorageQuota {
    guard let json = try? JSONDecoder().decode(DriveAboutJSON.self, from: data) else {
        throw MarkSweepError.decode
    }
    let usage = int64Field(json.storageQuota?.usage) ?? 0
    return StorageQuota(usage: usage, limit: int64Field(json.storageQuota?.limit))
}
