import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ProxmoxViewModel
    @ObservedObject var settings: SettingsService
    @ObservedObject var launchService: LaunchAtLoginService
    @ObservedObject var updaterController: UpdaterController

    @Environment(\.colorScheme) var colorScheme

    enum Screen {
        case dashboard
        case settings
    }

    @State private var currentScreen: Screen = .dashboard
    @State private var isRefreshing: Bool = false

    private var statusColor: Color {
        switch viewModel.appState {
        case .running: return .green
        case .stopped: return .gray
        case .loading: return .orange
        case .error: return .red
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

    private var headerIcon: NSImage {
        // Try Bundle.module (Dev/Xcode - DEBUG ONLY)
        #if DEBUG
        if let moduleUrl = Bundle.module.url(forResource: "Assets/MenuBarIcon", withExtension: "png"),
           let image = NSImage(contentsOf: moduleUrl) {
            image.isTemplate = true
            return image
        }
        #endif
        
        // Try Bundle.main (Production/Manual Build)
        if let resourcePath = Bundle.main.resourcePath {
            let iconPath = resourcePath + "/MenuBarIcon.png"
            if let image = NSImage(contentsOfFile: iconPath) {
                 image.isTemplate = true
                 return image
            }
        }
        return NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil) ?? NSImage()
    }

    var body: some View {
        ZStack {
            if currentScreen == .dashboard {
                dashboardContent
                    .transition(.move(edge: .leading))
            } else {
                SettingsView(settings: settings, launchService: launchService, updaterController: updaterController) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentScreen = .dashboard
                    }
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentScreen)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
        .background(WindowAccessor { window in
            guard let window = window else { return }
            if window.styleMask.contains(.resizable) {
                window.styleMask.remove(.resizable)
            }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.isOpaque = false
        })
        .background(CursorFixView())
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active))
        .task {
            while !Task.isCancelled {
                await viewModel.loadData()
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5s
            }
        }
    }

    var dashboardContent: some View {
        VStack(spacing: 0) {

            VStack(spacing: 12) {
                HStack {
                    Image(nsImage: headerIcon)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 2) {
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
                                Text(viewModel.selectedServerId == nil ? "no server selected" : (settings.servers.first(where: { $0.id == viewModel.selectedServerId })?.name ?? "Unknown"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .contentShape(Rectangle())
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()

                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                    
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
                                .symbolEffect(.rotate, options: .speed(10.0) ,isActive: isRefreshing)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.borderless)

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
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
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
            .background(.thinMaterial)

            Divider()

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
                                if viewModel.resourceFilter == filter {
                                    Label(filter.rawValue, systemImage: filter.icon)
                                } else {
                                    Label(filter.rawValue, systemImage: filter.icon)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text(viewModel.resourceFilter.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 6)
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
            .padding(.vertical, 8)

            if viewModel.filteredVMs.isEmpty {
                VStack {
                    if settings.servers.isEmpty {
                        Text("No server found")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)

                        Button("Add a Server") {
                            withAnimation { currentScreen = .settings }
                        }
                        .padding()
                        Spacer()
                    } else if let fullError = viewModel.errorMessage {
                        let (title, description) = {
                            let parts = fullError.components(separatedBy: ": ")
                            if parts.count > 1 {
                                return (parts[0], parts.dropFirst().joined(separator: ": "))
                            } else {
                                return ("Error", fullError)
                            }
                        }()

                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 22))
                                .foregroundColor(.red)
                                .padding(.bottom, 4)

                            Text(title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Text(description)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        Spacer()
                    } else {
                        Spacer()
                        Text("No VMs found")
                            .foregroundColor(.secondary)
                        Spacer()

                        if viewModel.searchText.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.adaptiveOrange)
                                    .font(.system(size: 14))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Missing Resources?")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Ensure 'Privilege Separation' is unchecked in your API Token settings.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.adaptiveOrange.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.adaptiveOrange.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        HStack {
                            Text("\(viewModel.filteredVMs.count) \(viewModel.filteredVMs.count == 1 ? "RESOURCE" : "RESOURCES")")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        ForEach(Array(viewModel.filteredVMs.enumerated()), id: \.element.id) { index, vm in
                            VMRow(vm: vm, viewModel: viewModel)
                            if index < viewModel.filteredVMs.count - 1 {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ActionStatusButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isHovered ? Color.white.opacity(0.1) : Color.clear)
            .background(.regularMaterial)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct VMRow: View {
    let vm: ProxmoxVM
    @ObservedObject var viewModel: ProxmoxViewModel
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(vm.isRunning ? Color.adaptiveGreen.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 28, height: 28)

                Image(systemName: vm.type == "lxc" ? "cube.box" : "display")
                    .font(.system(size: 12))
                    .foregroundColor(vm.isRunning ? .adaptiveGreen : .gray)
                    .frame(width: 14)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(vm.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("(\(vm.node))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Text("\(vm.vmid)")
                        .font(.system(size: 10, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)

                    Text(vm.status.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(vm.isRunning ? .adaptiveGreen : .secondary)

                    if vm.isRunning {
                        let cpuVal = vm.cpu ?? 0
                        let memVal = (vm.maxmem ?? 0) > 0 ? Double(vm.mem ?? 0) / Double(vm.maxmem!) : 0

                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))

                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                            .foregroundColor(getUsageColor(cpuVal))
                        Text(vm.cpuUsage)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(getUsageColor(cpuVal))

                        Image(systemName: "memorychip")
                            .font(.system(size: 10))
                            .foregroundColor(getUsageColor(memVal))
                            .padding(.leading, 4)
                        Text(vm.memUsage)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(getUsageColor(memVal))

                        if vm.type != "qemu", let maxdisk = vm.maxdisk, maxdisk > 0 {
                            let diskVal = Double(vm.disk ?? 0) / Double(maxdisk)

                            Image(systemName: "internaldrive")
                                .font(.system(size: 10))
                                .foregroundColor(getUsageColor(diskVal))
                                .padding(.leading, 4)
                            Text(vm.diskUsage)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(getUsageColor(diskVal))
                        }
                    }
                }
            }

            Spacer()

            if viewModel.processingVMIDs.contains(vm.vmid) {
                if #available(macOS 15.0, *) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .symbolEffect(.rotate, options: .repeating)
                        .frame(width: 20, height: 20)
                } else {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 20, height: 20)
                }
            } else {
                if vm.isRunning {
                     Button {
                        Task {
                            await viewModel.restartVM(vm)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.adaptiveOrange)
                            .frame(width: 20, height: 20)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Restart")
                }

                Button {
                    Task {
                        await viewModel.toggleVMState(vm)
                    }
                } label: {
                    Image(systemName: vm.isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(vm.isRunning ? .adaptiveRed : .adaptiveGreen)
                        .frame(width: 20, height: 20)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(vm.isRunning ? "Stop (Shutdown)" : "Start")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            viewModel.openVMInBrowser(vm)
        }
        .help("Open in Web Browser")
    }

    private func getUsageColor(_ value: Double) -> Color {
        if value >= 0.95 {
            return .adaptiveRed
        } else if value >= 0.8 {
            return .adaptiveOrange
        } else {
            return .primary
        }
    }
}

extension Color {
    static var adaptiveGreen: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor.green : NSColor(displayP3Red: 0, green: 0.6, blue: 0, alpha: 1)
        }))
    }
    
    static var adaptiveRed: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor.red : NSColor(displayP3Red: 0.8, green: 0, blue: 0, alpha: 1)
        }))
    }
    
    static var adaptiveOrange: Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor.orange : NSColor(displayP3Red: 0.8, green: 0.4, blue: 0, alpha: 1)
        }))
    }
}
