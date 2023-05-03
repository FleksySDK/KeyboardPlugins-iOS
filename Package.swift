// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "FleksyApps",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "FleksyApps",
            targets: [
                "BaseFleksyApp",
                "GiphyApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/FleksySDK/iOS-FleksyAppsCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "BaseFleksyApp",
            dependencies: [
                .product(name: "FleksyAppsCore", package: "ios-fleksyappscore"),
            ]),
        .target(
            name: "GiphyApp",
            dependencies: ["BaseFleksyApp"],
            resources: [.process("Media.xcassets")]
        ),
    ]
)
