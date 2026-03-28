// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Wisp",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "Wisp",
            dependencies: [
                "WhisperKit",
            ],
            path: "Wisp",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "WispTests",
            dependencies: ["Wisp"],
            path: "WispTests",
            resources: [
                .process("Fixtures"),
            ]
        ),
    ]
)
