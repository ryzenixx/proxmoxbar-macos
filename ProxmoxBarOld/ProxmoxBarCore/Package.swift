// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProxmoxBarCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ProxmoxBarCore", targets: ["ProxmoxBarCore"])
    ],
    targets: [
        .target(
            name: "ProxmoxBarCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "ProxmoxBarCoreTests",
            dependencies: ["ProxmoxBarCore"],
            resources: [
                .process("Fixtures")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
