// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ProxmoxBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ProxmoxBar", targets: ["ProxmoxBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.0")
    ],
    targets: [
        .executableTarget(
            name: "ProxmoxBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources",
            resources: [
                .copy("Assets")
            ]
        ),
        .testTarget(
            name: "ProxmoxBarTests",
            dependencies: ["ProxmoxBar"],
            path: "Tests/ProxmoxBarTests"
        )
    ]
)
