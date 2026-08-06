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
        switch model.phase {
        case .loaded(let state):
            VStack(spacing: 0) {
                ClusterSummaryRow(state: state, isStale: model.isStale)
                Divider()
                GuestList(guests: state.guests)
            }
        case .failed(let message):
            PagePlaceholder(symbol: "exclamationmark.triangle", message: message)
        case .idle, .loading:
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
