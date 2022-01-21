// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUISegues",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftUISegues",
            targets: ["SwiftUISegues"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftUISegues",
            dependencies: []),
        .testTarget(
            name: "SwiftUISeguesTests",
            dependencies: ["SwiftUISegues"]),
    ]
)
