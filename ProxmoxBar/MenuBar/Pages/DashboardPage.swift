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
                DashboardHeader(
                    servers: model.servers,
                    selected: model.selected,
                    onSelect: { model.select($0) },
                    onAddServer: { router.go(to: .addServer) },
                    onOpenSettings: { router.go(to: .settings) }
                )
                Divider()
                content
            }
            .task {
                model.startMonitoring()
            }
            .onChange(of: store.servers) { _, _ in
                model.selectionDidChange()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let message = model.failureMessage {
            DashboardFailure(message: message) {
                await model.refresh()
            }
        } else if let state = model.visibleState {
            VStack(spacing: 0) {
                ClusterSummaryRow(state: state)
                Divider()
                GuestList(guests: state.guests)
            }
        } else {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
