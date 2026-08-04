// swift-tools-version: 6.0
import PackageDescription

// The logic layer of ProxmoxBar: domain models, the Proxmox API client, and
// later the storage and certificate trust layers.
//
// This package imports Foundation and Security, never SwiftUI or AppKit. That
// boundary is the point: it is checked by the compiler rather than by
// discipline. See docs/ADR/0017.

let package = Package(
    name: "ProxmoxCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ProxmoxCore", targets: ["ProxmoxCore"])
    ],
    targets: [
        // The test target is declared in the last step of 3.0.0, against the
        // shape that actually ships rather than one being replaced.
        // See docs/Roadmap.md and docs/ADR/0022.
        .target(
            name: "ProxmoxCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
