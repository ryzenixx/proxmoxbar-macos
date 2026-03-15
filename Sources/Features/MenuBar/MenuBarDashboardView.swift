import SwiftUI

struct MenuBarDashboardView: View {
    @ObservedObject var viewModel: ProxmoxViewModel
    @ObservedObject var settings: SettingsService

    @Binding var selectedTab: MenuBarView.Tab
    @Binding var currentScreen: MenuBarView.Screen
    @Binding var isRefreshing: Bool

    private var statusColor: Color {
        switch viewModel.appState {
        case .running: .green
        case .stopped: .gray
        case .loading: .orange
        case .error: .red
        }
    }

    private var statusText: String {
        switch viewModel.appState {
        case .running: return "CONNECTED"
        case .stopped: return "DISCONNECTED"
        case .loading(let text): return text
        case .error: return "ERROR"
        }
    }

    private var selectedServerName: String {
        guard let selectedServerId = viewModel.selectedServerId else {
            return "no server selected"
        }
        return settings.servers.first(where: { $0.id == selectedServerId })?.name ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            tabSection

            if selectedTab == .resources {
                resourceToolbar
            }

            if selectedTab == .resources {
                ResourceListView(
                    viewModel: viewModel,
                    settings: settings,
                    currentScreen: $currentScreen
                )
            } else {
                StorageListView(viewModel: viewModel)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(nsImage: MenuBarAssets.headerIcon)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 2) {
                    serverSelector
                    statusIndicator
                }

                Spacer()

                refreshButton
                settingsMenu
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, viewModel.clusterStats == nil ? 16 : 4)

            if let stats = viewModel.clusterStats {
                VStack(spacing: 8) {
                    ClusterStatsRow(node: stats)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }

    private var serverSelector: some View {
        Menu {
            ForEach(settings.servers) { server in
                Button {
                    viewModel.selectedServerId = server.id
                    Task { await viewModel.loadData() }
                } label: {
                    if viewModel.selectedServerId == server.id {
                        Label(server.name, systemImage: "checkmark")
                    } else {
                        Text(server.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedServerName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    private var refreshButton: some View {
        Button {
            isRefreshing = true
            Task {
                await viewModel.loadData()
                try? await Task.sleep(nanoseconds: 500_000_000)
                isRefreshing = false
            }
        } label: {
            if #available(macOS 15.0, *) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .symbolEffect(.rotate, options: .speed(10.0), isActive: isRefreshing)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }

    private var settingsMenu: some View {
        Menu {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentScreen = .settings
                }
            } label: {
                Label("Settings", systemImage: "gear")
            }

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Proxmox Bar", systemImage: "power")
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var tabSection: some View {
        HStack {
            Spacer()

            Picker("", selection: $selectedTab) {
                Text("Resources").tag(MenuBarView.Tab.resources)
                Text("Storage").tag(MenuBarView.Tab.storage)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var resourceToolbar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search resources...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))

                Menu {
                    ForEach(ProxmoxViewModel.ResourceFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.resourceFilter = filter
                        } label: {
                            Label(filter.rawValue, systemImage: filter.icon)
                        }
                    }
                } label: {
                    Text(viewModel.resourceFilter.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.leading, 6)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Divider()
                    .frame(height: 12)

                Menu {
                    ForEach(ProxmoxViewModel.SortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            if viewModel.sortOption == option {
                                Label(option.rawValue, systemImage: "checkmark")
                            } else {
                                Label(option.rawValue, systemImage: option.icon)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(10)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.top, 0)
        .padding(.bottom, 8)
    }
}

private enum MenuBarAssets {
    static var headerIcon: NSImage {
        if let resourcePath = Bundle.main.resourcePath {
            let iconPath = resourcePath + "/MenuBarIcon.png"
            if let image = NSImage(contentsOfFile: iconPath) {
                image.isTemplate = true
                return image
            }
        }

        return NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil) ?? NSImage()
    }
}
