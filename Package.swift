// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Hero2",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Hero2",
            targets: ["Hero2"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/lkzhao/BaseToolbox", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "Hero2",
            dependencies: ["BaseToolbox"]
        )
    ]
)
