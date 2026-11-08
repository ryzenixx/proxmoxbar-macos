import AppKit
import SwiftUI

struct DashboardHeader: View {
    let servers: [ServerConfiguration]
    let selected: ServerConfiguration?
    let onSelect: (UUID) -> Void
    let onAddServer: () -> Void
    let onOpenSettings: () -> Void
    var titleOverride: String?
    var onExitDemo: (() -> Void)?

    var body: some View {
        HStack(spacing: 2) {
            ServerSelector(
                servers: servers,
                selected: selected,
                onSelect: onSelect,
                onAddServer: onAddServer,
                titleOverride: titleOverride
            )
            Spacer(minLength: 8)
            if let onExitDemo {
                Button(action: onExitDemo) {
                    Label("Exit demo", systemImage: "xmark")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.red)
            }
            PanelIconButton(symbol: "gearshape", title: "Settings", action: onOpenSettings)
            PanelIconButton(symbol: "power", title: "Quit ProxmoxBar") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}
