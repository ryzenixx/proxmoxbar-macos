import SwiftUI

struct DashboardPage: View {
    @Environment(PanelRouter.self) private var router
    @Environment(ServerStore.self) private var store

    var body: some View {
        if store.servers.isEmpty {
            NoServersView {
                router.go(to: .addServer)
            }
        } else {
            PagePlaceholder(
                symbol: "chart.bar.fill",
                message: "\(store.servers.count) server connected"
            )
        }
    }
}
