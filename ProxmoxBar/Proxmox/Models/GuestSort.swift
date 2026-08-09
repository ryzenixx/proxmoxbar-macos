import Foundation

enum GuestSort: String, CaseIterable, Sendable {
    case identifier = "ID"
    case name = "Name"
    case status = "Status"

    var symbol: String {
        switch self {
        case .identifier: "number"
        case .name: "textformat"
        case .status: "bolt.fill"
        }
    }

    func arrange(_ guests: [ProxmoxGuest], matching search: String) -> [ProxmoxGuest] {
        let query = search.trimmingCharacters(in: .whitespaces)
        let matches =
            query.isEmpty
            ? guests
            : guests.filter {
                $0.displayName.localizedCaseInsensitiveContains(query)
                    || String($0.vmid).contains(query)
            }
        return matches.sorted(by: isOrderedBefore)
    }

    private func isOrderedBefore(_ lhs: ProxmoxGuest, _ rhs: ProxmoxGuest) -> Bool {
        switch self {
        case .identifier:
            return lhs.vmid < rhs.vmid
        case .name:
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
                == .orderedAscending
        case .status:
            if lhs.status.isRunning != rhs.status.isRunning { return lhs.status.isRunning }
            return lhs.vmid < rhs.vmid
        }
    }
}
