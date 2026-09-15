import Foundation

public let markSweepVersion = "0.1.0"

public struct MarkSweepSettings: Equatable, Codable {
    public var lastEmail: String?
    public var largeBytesThreshold: Int
    public var perQueryCap: Int

    public static let `default` = MarkSweepSettings(
        lastEmail: nil,
        largeBytesThreshold: 5_000_000,
        perQueryCap: 500
    )

    public init(lastEmail: String?, largeBytesThreshold: Int, perQueryCap: Int) {
        self.lastEmail = lastEmail
        self.largeBytesThreshold = largeBytesThreshold
        self.perQueryCap = perQueryCap
    }
}

public func defaultSettingsURL() -> URL {
    let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return root.appendingPathComponent("MarkSweep/settings.json")
}

public func loadSettings(from url: URL) -> MarkSweepSettings {
    guard let data = try? Data(contentsOf: url) else { return .default }
    return (try? JSONDecoder().decode(MarkSweepSettings.self, from: data)) ?? .default
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
        perQueryCap: settings.perQueryCap
    )
}
