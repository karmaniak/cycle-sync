// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CycleCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "CycleCore", targets: ["CycleCore"]),
    ],
    targets: [
        .target(name: "CycleCore"),
        .testTarget(name: "CycleCoreTests", dependencies: ["CycleCore"]),
    ]
)
