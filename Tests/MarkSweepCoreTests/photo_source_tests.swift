import XCTest
@testable import MarkSweepCore

final class PhotoSourceTests: XCTestCase {
    func testStubListThrows() async {
        await XCTAssertThrows(PhotoSourceError.notAvailable) {
            _ = try await StubPhotoSource().listMarkedAssets()
        }
    }

    func testStubThumbnailThrows() async {
        await XCTAssertThrows(PhotoSourceError.notAvailable) {
            _ = try await StubPhotoSource().thumbnailData(for: "x")
        }
    }

    func testStubDeleteThrows() async {
        await XCTAssertThrows(PhotoSourceError.notAvailable) {
            try await StubPhotoSource().deleteAssets(ids: ["x"])
        }
    }

    func testAssetRefEquality() {
        let date = Date(timeIntervalSince1970: 1)
        XCTAssertEqual(PhotoAssetRef(id: "a", created: date), PhotoAssetRef(id: "a", created: date))
    }
}

func XCTAssertThrows<E: Error & Equatable>(
    _ expected: E,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ work: () async throws -> Void
) async {
    do {
        try await work()
        XCTFail("expected throw", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expected, file: file, line: line)
    } catch {
        XCTFail("wrong error \(error)", file: file, line: line)
    }
}
