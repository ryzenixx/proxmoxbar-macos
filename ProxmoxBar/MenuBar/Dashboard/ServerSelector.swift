import SwiftUI

struct ServerSelector: View {
    let servers: [ServerConfiguration]
    let selected: ServerConfiguration?
    let onSelect: (UUID) -> Void
    let onAddServer: () -> Void

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
                Text(selected?.displayName ?? "No server")
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
