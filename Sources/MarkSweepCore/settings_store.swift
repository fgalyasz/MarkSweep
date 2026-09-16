import Foundation

enum SettingsKey: String, CodingKey {
    case lastEmail
    case largeBytesThreshold
    case perQueryCap
    case sweptCount
    case sweptBytes
    case keepRules
}

public let markSweepVersion = "0.1.0"

public struct MarkSweepSettings: Equatable {
    public var lastEmail: String?
    public var largeBytesThreshold: Int
    public var perQueryCap: Int
    public var sweptCount: Int
    public var sweptBytes: Int
    public var keepRules: [KeepRule]

    public static let `default` = MarkSweepSettings(
        lastEmail: nil,
        largeBytesThreshold: 5_000_000,
        perQueryCap: 40,
        sweptCount: 0,
        sweptBytes: 0,
        keepRules: []
    )

    public init(
        lastEmail: String?,
        largeBytesThreshold: Int,
        perQueryCap: Int,
        sweptCount: Int = 0,
        sweptBytes: Int = 0,
        keepRules: [KeepRule] = []
    ) {
        self.lastEmail = lastEmail
        self.largeBytesThreshold = largeBytesThreshold
        self.perQueryCap = perQueryCap
        self.sweptCount = sweptCount
        self.sweptBytes = sweptBytes
        self.keepRules = keepRules
    }
}

extension MarkSweepSettings: Codable {
    public init(from decoder: Decoder) throws {
        self = try decodeSettings(decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try encodeSettings(self, encoder: encoder)
    }
}

func decodeSettings(_ decoder: Decoder) throws -> MarkSweepSettings {
    let c = try decoder.container(keyedBy: SettingsKey.self)
    return MarkSweepSettings(
        lastEmail: try c.decodeIfPresent(String.self, forKey: .lastEmail),
        largeBytesThreshold: try c.decodeIfPresent(Int.self, forKey: .largeBytesThreshold) ?? 5_000_000,
        perQueryCap: try c.decodeIfPresent(Int.self, forKey: .perQueryCap) ?? 40,
        sweptCount: try c.decodeIfPresent(Int.self, forKey: .sweptCount) ?? 0,
        sweptBytes: try c.decodeIfPresent(Int.self, forKey: .sweptBytes) ?? 0,
        keepRules: try c.decodeIfPresent([KeepRule].self, forKey: .keepRules) ?? []
    )
}

func encodeSettings(_ settings: MarkSweepSettings, encoder: Encoder) throws {
    var c = encoder.container(keyedBy: SettingsKey.self)
    try c.encodeIfPresent(settings.lastEmail, forKey: .lastEmail)
    try c.encode(settings.largeBytesThreshold, forKey: .largeBytesThreshold)
    try c.encode(settings.perQueryCap, forKey: .perQueryCap)
    try c.encode(settings.sweptCount, forKey: .sweptCount)
    try c.encode(settings.sweptBytes, forKey: .sweptBytes)
    try c.encode(settings.keepRules, forKey: .keepRules)
}

public func defaultSettingsURL() -> URL {
    let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return root.appendingPathComponent("MarkSweep/settings.json")
}

public func loadSettings(from url: URL) -> MarkSweepSettings {
    guard let data = try? Data(contentsOf: url) else { return .default }
    let loaded = (try? JSONDecoder().decode(MarkSweepSettings.self, from: data)) ?? .default
    let migrated = uniquedKeepSettings(migrateSettings(loaded))
    if migrated != loaded { try? saveSettings(migrated, to: url) }
    return migrated
}

public func migrateSettings(_ settings: MarkSweepSettings) -> MarkSweepSettings {
    if settings.perQueryCap != 500 { return settings }
    return MarkSweepSettings(
        lastEmail: settings.lastEmail,
        largeBytesThreshold: settings.largeBytesThreshold,
        perQueryCap: MarkSweepSettings.default.perQueryCap,
        sweptCount: settings.sweptCount,
        sweptBytes: settings.sweptBytes,
        keepRules: settings.keepRules
    )
}

public func saveSettings(_ settings: MarkSweepSettings, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    let data = try JSONEncoder().encode(settings)
    try data.write(to: url, options: .atomic)
}

public func settingsWithEmail(_ settings: MarkSweepSettings, email: String?) -> MarkSweepSettings {
    MarkSweepSettings(
        lastEmail: email,
        largeBytesThreshold: settings.largeBytesThreshold,
        perQueryCap: settings.perQueryCap,
        sweptCount: settings.sweptCount,
        sweptBytes: settings.sweptBytes,
        keepRules: settings.keepRules
    )
}

public func settingsByAddingSweep(_ settings: MarkSweepSettings, count: Int, bytes: Int) -> MarkSweepSettings {
    MarkSweepSettings(
        lastEmail: settings.lastEmail,
        largeBytesThreshold: settings.largeBytesThreshold,
        perQueryCap: settings.perQueryCap,
        sweptCount: settings.sweptCount + count,
        sweptBytes: settings.sweptBytes + bytes,
        keepRules: settings.keepRules
    )
}

public func settingsByReplacingKeepRules(_ settings: MarkSweepSettings, rules: [KeepRule]) -> MarkSweepSettings {
    MarkSweepSettings(
        lastEmail: settings.lastEmail,
        largeBytesThreshold: settings.largeBytesThreshold,
        perQueryCap: settings.perQueryCap,
        sweptCount: settings.sweptCount,
        sweptBytes: settings.sweptBytes,
        keepRules: rules
    )
}
