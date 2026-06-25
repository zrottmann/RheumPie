// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RheumPie",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // xtool expects exactly one library product = the main app.
        .library(
            name: "RheumPie",
            targets: ["RheumPie"]
        ),
    ],
    targets: [
        .target(
            name: "RheumPie",
            // Swift 5 language mode: relaxes strict-concurrency isolation to
            // warnings for SwiftUI interop (ARKit, camera, AVFoundation).
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "RheumPieTests",
            dependencies: ["RheumPie"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
