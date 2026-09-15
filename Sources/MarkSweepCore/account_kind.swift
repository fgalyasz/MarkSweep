import Foundation

public enum AccountKind: String, Codable, CaseIterable, Identifiable {
    case gmail
    case iCloudPhotos
    case googlePhotos

    public var id: String { rawValue }
}

public func accountKindTitle(_ kind: AccountKind) -> String {
    switch kind {
    case .gmail: return "Gmail"
    case .iCloudPhotos: return "iCloud Photos"
    case .googlePhotos: return "Google Photos"
    }
}

public func accountKindIsEnabled(_ kind: AccountKind) -> Bool {
    kind == .gmail
}

public func accountKindComingSoon(_ kind: AccountKind) -> String? {
    if accountKindIsEnabled(kind) { return nil }
    return "Coming soon"
}
