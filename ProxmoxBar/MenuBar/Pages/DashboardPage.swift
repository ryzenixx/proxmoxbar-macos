import SwiftUI

private enum DashboardSection: String, CaseIterable {
    case machines = "Machines"
    case storage = "Storage"
}

struct DashboardPage: View {
    @Environment(PanelRouter.self) private var router
    @Environment(ServerStore.self) private var store
    @Environment(DashboardModel.self) private var model
    @Environment(GuestListPreferences.self) private var preferences

    @State private var section: DashboardSection = .machines
    @State private var search = ""

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
                DashboardToolbar(
                    search: $search,
                    showsSort: section == .machines,
                    sort: preferences.sort,
                    onSelectSort: { preferences.sort = $0 }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                list(for: state)
            }
        } else {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func list(for state: ClusterState) -> some View {
        switch section {
        case .machines:
            let guests = preferences.sort.arrange(state.guests, matching: search)
            if guests.isEmpty, !search.isEmpty {
                PagePlaceholder(symbol: "magnifyingglass", message: "No matches")
            } else {
                GuestList(guests: guests)
            }
        case .storage:
            let storages = filteredStorages(of: state)
            if storages.isEmpty, !search.isEmpty {
                PagePlaceholder(symbol: "magnifyingglass", message: "No matches")
            } else {
                StorageList(storages: storages)
            }
        }
    }

    private func filteredStorages(of state: ClusterState) -> [ProxmoxStorage] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return state.distinctStorages }
        return state.distinctStorages.filter {
            $0.name.localizedCaseInsensitiveContains(query)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
