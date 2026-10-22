// swift-tools-version: 6.0
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import PackageDescription

let package = Package(
    name: "FangenCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FangenCore", targets: ["FangenCore"]),
    ],
    targets: [
        .target(name: "FangenCore"),
        .testTarget(name: "FangenCoreTests", dependencies: ["FangenCore"]),
    ]
)
