import Foundation

struct GuestStatusChange: Equatable, Sendable {
    let id: String
    let name: String
    let vmid: Int
    let status: GuestStatus

    var title: String {
        "\(name) (\(vmid))"
    }

    var body: String {
        "is now \(status.label.lowercased())."
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

@MainActor
protocol StatusChangeNotifier {
    func post(_ change: GuestStatusChange)
}

struct SilentNotifier: StatusChangeNotifier {
    func post(_ change: GuestStatusChange) {}
}
