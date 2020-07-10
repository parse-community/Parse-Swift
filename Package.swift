// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "ParseSwift",
    products: [
        .library(
            name: "ParseSwift",
            targets: ["ParseSwift"])
    ],
    targets: [
        .target(
            name: "ParseSwift",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "ParseSwiftTests",
            dependencies: ["ParseSwift"])
    ]
)
