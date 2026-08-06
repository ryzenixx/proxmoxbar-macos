import SwiftUI

struct DashboardPage: View {
    @Environment(PanelRouter.self) private var router
    @Environment(ServerStore.self) private var store
    @Environment(DashboardModel.self) private var model

    var body: some View {
        if store.servers.isEmpty {
            NoServersView {
                router.go(to: .addServer)
            }
        } else {
            VStack(spacing: 0) {
                ServerSelector(
                    servers: model.servers,
                    selected: model.selected,
                    onSelect: { model.select($0) },
                    onAddServer: { router.go(to: .addServer) }
                )
                Divider()
                PagePlaceholder(
                    symbol: "chart.bar.fill",
                    message: model.selected?.address ?? "Nothing selected"
                )
            }
            .onChange(of: store.servers) { _, _ in
                model.selectionDidChange()
            }
        }
    }
}
