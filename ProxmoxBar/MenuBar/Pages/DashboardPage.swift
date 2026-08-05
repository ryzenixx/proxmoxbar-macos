import SwiftUI

struct DashboardPage: View {
    @Environment(PanelRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            PagePlaceholder(symbol: "server.rack", message: "No server configured")
            HStack {
                Button {
                    router.go(to: .settings)
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}
