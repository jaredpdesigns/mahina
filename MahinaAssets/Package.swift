// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MahinaAssets",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "MahinaAssets",
            targets: ["MahinaAssets"]
        ),
    ],
    targets: [
        .target(
            name: "MahinaAssets",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "MahinaAssetsTests",
            dependencies: ["MahinaAssets"],
            path: "Tests"
        ),
    ]
)
