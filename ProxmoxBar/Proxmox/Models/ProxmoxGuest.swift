import Foundation

struct ProxmoxGuest: Identifiable, Hashable, Sendable {
    let id: String
    let vmid: Int
    let kind: GuestKind
    let node: String
    let name: String?
    let status: GuestStatus
    let isTemplate: Bool
    let lock: String?
    let tags: [String]
    let pool: String?
    let haState: String?

    let cpu: Double?
    let maxCPUs: Double?
    let memory: Int?
    let maximumMemory: Int?
    let disk: Int?
    let maximumDisk: Int?
    let uptime: Int?

    var displayName: String {
        guard let name, name.isEmpty == false else { return String(vmid) }
        return name
    }

    var isLocked: Bool {
        guard let lock else { return false }
        return lock.isEmpty == false
    }

    var acceptsPowerActions: Bool {
        isTemplate == false && isLocked == false
    }

    var isHighlyAvailable: Bool {
        guard let haState else { return false }
        return haState.isEmpty == false && haState != "ignored"
    }
}
