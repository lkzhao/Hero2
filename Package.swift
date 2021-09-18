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
  dependencies: [],
  targets: [
    .target(
      name: "Hero2",
      dependencies: []
    )
  ]
)
