// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ParseSwift",
    platforms: [.iOS(.v13),
                .macCatalyst(.v13),
                .macOS(.v10_15),
                .tvOS(.v13),
                .watchOS(.v6)],
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
            dependencies: ["ParseSwift"],
            exclude: ["Info.plist"])
    ]
)
