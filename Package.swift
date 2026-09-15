// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkSweep",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MarkSweepCore", targets: ["MarkSweepCore"]),
        .executable(name: "MarkSweep", targets: ["MarkSweep"])
    ],
    targets: [
        .target(name: "MarkSweepCore", dependencies: []),
        .executableTarget(
            name: "MarkSweep",
            dependencies: ["MarkSweepCore"],
            path: "Sources/MarkSweep"
        ),
        .testTarget(
            name: "MarkSweepCoreTests",
            dependencies: ["MarkSweepCore"]
        )
    ]
)
