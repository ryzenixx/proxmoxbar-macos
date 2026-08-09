import SwiftUI

private enum DashboardSection: String, CaseIterable {
    case machines = "Machines"
    case storage = "Storage"
}

struct DashboardPage: View {
    @Environment(PanelRouter.self) private var router
    @Environment(ServerStore.self) private var store
    @Environment(DashboardModel.self) private var model

    @State private var section: DashboardSection = .machines

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
                await model.refresh()
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
                sectionPicker
                switch section {
                case .machines:
                    GuestList(guests: state.guests)
                case .storage:
                    StorageList(storages: state.distinctStorages)
                }
            }
        } else {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sectionPicker: some View {
        Picker("", selection: $section) {
            ForEach(DashboardSection.allCases, id: \.self) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.small)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
