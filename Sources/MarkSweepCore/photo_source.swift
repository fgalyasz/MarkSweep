import Foundation

public protocol PhotoSource {
    func listMarkedAssets() async throws -> [PhotoAssetRef]
    func thumbnailData(for id: String) async throws -> Data
    func deleteAssets(ids: [String]) async throws
}

public struct PhotoAssetRef: Equatable {
    public let id: String
    public let created: Date

    public init(id: String, created: Date) {
        self.id = id
        self.created = created
    }
}

public enum PhotoSourceError: Error, Equatable {
    case notAvailable
}

public struct StubPhotoSource: PhotoSource {
    public init() {}

    public func listMarkedAssets() async throws -> [PhotoAssetRef] {
        throw PhotoSourceError.notAvailable
    }

    public func thumbnailData(for id: String) async throws -> Data {
        throw PhotoSourceError.notAvailable
    }

    public func deleteAssets(ids: [String]) async throws {
        throw PhotoSourceError.notAvailable
    }
}
