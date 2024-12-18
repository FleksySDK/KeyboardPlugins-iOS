// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FleksyApps",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "FleksyApps",
            targets: [
                "BaseFleksyApp",
                "MediaShareApp",
                "GiphyApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/FleksySDK/iOS-FleksyAppsCore.git", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "BaseFleksyApp",
            dependencies: [
                .product(name: "FleksyAppsCore", package: "ios-fleksyappscore"),
            ]),
        .target(
            name: "MediaShareApp",
            dependencies: ["BaseFleksyApp"],
            resources: [.process("Media.xcassets")]
        ),
        .target(
            name: "GiphyApp",
            dependencies: ["BaseFleksyApp"],
            resources: [.process("Media.xcassets")]
        ),
    ]
)
