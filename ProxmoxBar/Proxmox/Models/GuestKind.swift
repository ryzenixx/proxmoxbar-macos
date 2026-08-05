import Foundation

enum GuestKind: String, Hashable, Sendable, CaseIterable {
    case virtualMachine = "qemu"
    case container = "lxc"

    var pathComponent: String {
        rawValue
    }

    var label: String {
        switch self {
        case .virtualMachine: "VM"
        case .container: "LXC"
        }
    }
}
