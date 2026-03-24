// swift-tools-version: 5.9
import PackageDescription

// ForgeFit uses no third-party Swift packages in the MVP.
// All dependencies are Apple frameworks:
//   - SwiftUI, SwiftData (iOS 17+)
//   - UserNotifications (local notifications)
//
// When Firebase integration is added, add via Xcode SPM:
//   https://github.com/firebase/firebase-ios-sdk
//   Products needed: FirebaseAuth, FirebaseFirestore, FirebaseMessaging
//
// This Package.swift exists for CI/tooling; the primary target
// is the Xcode project ForgeFit.xcodeproj.

let package = Package(
    name: "ForgeFit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "ForgeFit", targets: ["ForgeFit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ForgeFit",
            path: "ForgeFit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ForgeFitTests",
            dependencies: ["ForgeFit"],
            path: "ForgeFitTests"
        )
    ]
)
