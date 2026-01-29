// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HDMSDataGenerator",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "HDMSDataGenerator",
            targets: ["HDMSDataGenerator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/emqx/CocoaMQTT.git", from: "2.1.0"),
    ],
    targets: [
        .target(
            name: "HDMSDataGenerator",
            dependencies: ["CocoaMQTT"],
            path: "HDMSDataGenerator"),
    ]
)
