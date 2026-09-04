// swift-tools-version: 6.2
import PackageDescription
let settings: [SwiftSetting] = [.defaultIsolation(MainActor.self), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]
let package = Package(
    name: "TestPkg",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "Models", swiftSettings: settings),
        .testTarget(name: "ModelsTests", dependencies: ["Models"], swiftSettings: settings),
    ]
)
