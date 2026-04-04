// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwGraphUI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "SwGraphUI",
            targets: ["SwGraphUI"]
        ),
        .executable(
            name: "Example",
            targets: ["Example"]
        ),
    ],
    targets: [
        .target(
            name: "SwGraphUI"
        ),
        .executableTarget(
            name: "Example",
            dependencies: ["SwGraphUI"],
            path: "Example"
        ),
        .testTarget(
            name: "SwGraphUITests",
            dependencies: ["SwGraphUI"]
        ),
    ]
)
