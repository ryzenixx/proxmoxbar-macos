import SwiftUI

struct GuestList: View {
    let guests: [ProxmoxGuest]

    @Environment(DashboardModel.self) private var model
    @State private var expandedID: String?

    var body: some View {
        if guests.isEmpty {
            PagePlaceholder(symbol: "square.stack.3d.up", message: "No machines yet")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(guests) { guest in
                        GuestRow(
                            guest: guest,
                            isExpanded: expandedID == guest.id,
                            onToggle: { toggle(guest) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .animation(.snappy(duration: 0.18), value: expandedID)
            .onChange(of: model.actionFailures) { previous, current in
                guard let appeared = current.keys.first(where: { previous[$0] == nil }) else {
                    return
                }
                expandedID = appeared
            }
        }
    }

    private func toggle(_ guest: ProxmoxGuest) {
        expandedID = expandedID == guest.id ? nil : guest.id
    }
}
