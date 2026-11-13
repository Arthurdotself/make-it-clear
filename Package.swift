// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MakeItClear",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "MakeItClearCore"),
        .executableTarget(name: "MakeItClear", dependencies: ["MakeItClearCore"]),
        .testTarget(name: "MakeItClearCoreTests", dependencies: ["MakeItClearCore"]),
    ]
)
