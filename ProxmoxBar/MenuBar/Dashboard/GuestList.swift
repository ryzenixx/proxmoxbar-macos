import SwiftUI

struct GuestList: View {
    let guests: [ProxmoxGuest]

    var body: some View {
        if guests.isEmpty {
            PagePlaceholder(symbol: "square.stack.3d.up", message: "No machines yet")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(guests) { guest in
                        GuestRow(guest: guest)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
