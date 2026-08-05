import Foundation

struct ServerVersion: Hashable, Sendable {
    let version: String
    let release: String
    let repositoryID: String

    var displayName: String {
        "Proxmox VE \(version)"
    }
}
