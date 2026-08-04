// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProxmoxCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ProxmoxCore", targets: ["ProxmoxCore"])
    ],
    targets: [
        .target(
            name: "ProxmoxCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
