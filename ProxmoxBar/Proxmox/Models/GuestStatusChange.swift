import Foundation

struct StatusEvent: Equatable, Sendable {
    let title: String
    let body: String
}

struct GuestStatusChange: Equatable, Sendable {
    let id: String
    let name: String
    let vmid: Int
    let status: GuestStatus

    var event: StatusEvent {
        StatusEvent(title: "\(name) (\(vmid))", body: "is now \(status.label.lowercased()).")
    }

    static func detect(
        previous: [String: GuestStatus],
        current: [ProxmoxGuest],
        skipping: Set<String>
    ) -> [GuestStatusChange] {
        guard !previous.isEmpty else { return [] }
        return current.compactMap { guest in
            guard
                !skipping.contains(guest.id),
                let last = previous[guest.id],
                last != guest.status
            else { return nil }
            return GuestStatusChange(
                id: guest.id,
                name: guest.displayName,
                vmid: guest.vmid,
                status: guest.status
            )
        }
    }
}

struct NodeStatusChange: Equatable, Sendable {
    let name: String
    let isOnline: Bool

    var event: StatusEvent {
        StatusEvent(
            title: "Node \(name)",
            body: isOnline ? "is back online." : "went offline."
        )
    }

    static func detect(
        previous: [String: Bool],
        current: [ProxmoxNode]
    ) -> [NodeStatusChange] {
        guard !previous.isEmpty else { return [] }
        return current.compactMap { node in
            guard let was = previous[node.name], was != node.isOnline else { return nil }
            return NodeStatusChange(name: node.name, isOnline: node.isOnline)
        }
    }
}

@MainActor
protocol StatusChangeNotifier {
    func post(_ event: StatusEvent)
}

struct SilentNotifier: StatusChangeNotifier {
    func post(_ event: StatusEvent) {}
}
