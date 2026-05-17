// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "RestaurantOpsPurchasing",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RestaurantOpsPurchasingCore",
            targets: ["RestaurantOpsPurchasingCore"]
        )
    ],
    targets: [
        .target(
            name: "RestaurantOpsPurchasingCore",
            path: "RestaurantOpsPurchasing",
            exclude: [
                "RestaurantOpsPurchasingApp.swift",
                "Info.plist",
                "Assets.xcassets"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "RestaurantOpsPurchasingCoreTests",
            dependencies: ["RestaurantOpsPurchasingCore"],
            path: "RestaurantOpsPurchasingTests"
        )
    ]
)
