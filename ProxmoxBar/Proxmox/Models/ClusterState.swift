struct ClusterState: Hashable, Sendable {
    let nodes: [ProxmoxNode]
    let guests: [ProxmoxGuest]
    let storages: [ProxmoxStorage]

    func applying(_ statuses: [String: GuestStatus]) -> ClusterState {
        guard !statuses.isEmpty else { return self }
        return ClusterState(
            nodes: nodes,
            guests: guests.map { guest in
                guard let status = statuses[guest.id] else { return guest }
                var confirmed = guest
                confirmed.status = status
                return confirmed
            },
            storages: storages
        )
    }
}
