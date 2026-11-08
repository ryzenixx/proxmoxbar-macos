import SwiftUI

struct ServerSelector: View {
    let servers: [ServerConfiguration]
    let selected: ServerConfiguration?
    let onSelect: (UUID) -> Void
    let onAddServer: () -> Void
    var titleOverride: String?

    var body: some View {
        Menu {
            ForEach(servers) { server in
                Button {
                    onSelect(server.id)
                } label: {
                    if server.id == selected?.id {
                        Label(server.displayName, systemImage: "checkmark")
                    } else {
                        Text(server.displayName)
                    }
                }
            }
            Divider()
            Button("Add Server…", action: onAddServer)
        } label: {
            HStack(spacing: 7) {
                Image(.menuBarIcon)
                    .renderingMode(.template)
                    .foregroundStyle(.tint)
                Text(titleOverride ?? selected?.displayName ?? "No server")
                    .font(.headline)
                    .lineLimit(1)
            }
            .contentShape(.rect)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
