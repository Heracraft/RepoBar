// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RepoBar",
    platforms: [
        .macOS(.v15),
        .iOS(.v26),
    ],
    products: [
        .library(name: "Platform", targets: ["Platform"]),
        .library(name: "RepoBarCore", targets: ["RepoBarCore"]),
        // Named to avoid colliding with `RepoBar` on case-insensitive filesystems.
        .executable(name: "repobarcli", targets: ["repobarcli"]),
        // Linux GUI application (work in progress)
        // Note: This will fail to build on macOS due to conditional compilation
        // Build with: swift build --product repobar-linux (on Linux only)
        .executable(name: "repobar-linux", targets: ["repobar-linux"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/Commander", from: "0.2.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.2.2"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.8.0"),
        .package(url: "https://github.com/openid/AppAuth-iOS", from: "2.0.0"),
        .package(url: "https://github.com/apollographql/apollo-ios", from: "2.0.3"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.6.0"),
        .package(url: "https://github.com/steipete/Swiftdansi", from: "0.1.1"),
        .package(url: "https://github.com/apple/swift-markdown", from: "0.7.3"),
    ],
    targets: [
        .target(
            name: "Platform",
            dependencies: [],
            path: "Sources/Platform",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "RepoBarCore",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "RepoBar",
            dependencies: [
                "RepoBarCore",
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AppAuth", package: "AppAuth-iOS"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Logging", package: "swift-log"),
            ],
            exclude: ["Resources/Info.plist"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/RepoBar/Resources/Info.plist",
                ]),
                ]),
        .executableTarget(
            name: "repobarcli",
            dependencies: [
                .product(name: "Commander", package: "Commander"),
                .product(name: "Swiftdansi", package: "Swiftdansi"),
                "RepoBarCore",
            ],
            path: "Sources/repobarcli",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        // Linux GUI application (placeholder for now)
        // This target only builds on Linux due to #if os(Linux) in main.swift
        .executableTarget(
            name: "repobar-linux",
            dependencies: [
                "Platform",
                // "RepoBarCore", // Will be added once apollo-ios Linux support is fixed
            ],
            path: "Sources/repobar-linux",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "RepoBarTests",
            dependencies: ["RepoBar", "RepoBarCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
        .testTarget(
            name: "repobarcliTests",
            dependencies: ["repobarcli"],
            path: "Tests/repobarcliTests",
            resources: [
                .process("Fixtures"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
