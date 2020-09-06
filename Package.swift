// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ParseSwift",
    platforms: [.iOS(.v9), .macOS(.v10_12), .tvOS(.v9), .watchOS(.v3)],
    products: [
        .library(
            name: "ParseSwift",
            targets: ["ParseSwift"])
    ],
    targets: [
        .target(
            name: "ParseSwift",
            dependencies: []),
        .testTarget(
            name: "ParseSwiftTests",
            dependencies: ["ParseSwift"])
    ]
)
