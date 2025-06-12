// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MazeSolver",

    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],

    products: [
        .library(name: "MazeSolver", targets: ["MazeSolver"])
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-play-experimental", branch: "main"),
    ],

    targets: [
        .target(
            name: "MazeSolver",
            dependencies: [
                .product(name: "Playgrounds", package: "swift-play-experimental"),
            ]
        ),
        .testTarget(
            name: "MazeSolverTests",
            dependencies: ["MazeSolver"],
            resources: [.process("Resources")]
        )
    ]
)
