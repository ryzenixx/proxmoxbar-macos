import Foundation

struct ProxmoxGuest: Identifiable, Hashable, Sendable {
    let id: String
    let vmid: Int
    let kind: GuestKind
    let node: String
    let name: String?
    var status: GuestStatus
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

    var availableActions: [GuestAction] {
        guard acceptsPowerActions else { return [] }
        switch status {
        case .running: return [.shutdown, .reboot, .stop]
        case .stopped: return [.start]
        case .paused, .suspended: return [.resume, .stop]
        case .unknown: return []
        }
    }

    var memoryUsage: Double? {
        guard let memory, let maximumMemory, maximumMemory > 0 else { return nil }
        return min(Double(memory) / Double(maximumMemory), 1)
    }
}
