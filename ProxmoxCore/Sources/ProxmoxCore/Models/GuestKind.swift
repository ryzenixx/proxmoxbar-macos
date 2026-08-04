import Foundation

public enum GuestKind: String, Codable, Hashable, Sendable, CaseIterable {
    case qemu
    case lxc
    case openvz

    public var isVirtualMachine: Bool { self == .qemu }

    public var isContainer: Bool { self == .lxc || self == .openvz }
}
