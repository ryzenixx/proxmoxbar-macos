import SwiftUI

struct DashboardHeader: View {
    let servers: [ServerConfiguration]
    let selected: ServerConfiguration?
    let onSelect: (UUID) -> Void
    let onAddServer: () -> Void
    var titleOverride: String?
    var onExitDemo: (() -> Void)?

    var body: some View {
        HStack(spacing: 2) {
            if servers.isEmpty, titleOverride == nil {
                Text(PanelPage.dashboard.title)
                    .font(.headline)
            } else {
                ServerSelector(
                    servers: servers,
                    selected: selected,
                    onSelect: onSelect,
                    onAddServer: onAddServer,
                    titleOverride: titleOverride
                )
            }
            Spacer(minLength: 8)
            if let onExitDemo {
                Button(action: onExitDemo) {
                    Label("Exit demo", systemImage: "xmark")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.red)
            }
            PanelCommands()
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}
