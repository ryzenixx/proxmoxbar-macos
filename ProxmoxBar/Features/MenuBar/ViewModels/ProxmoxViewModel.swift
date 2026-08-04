import SwiftUI
import Combine
import ProxmoxCore

@MainActor
final class ProxmoxViewModel: ObservableObject {
    enum ResourceFilter: String, CaseIterable {
        case all = "All"
        case vm = "VM"
        case lxc = "LXC"

        var icon: String {
            switch self {
            case .all: return "server.rack"
            case .vm: return "display"
            case .lxc: return "cube.box"
            }
        }
    }

    enum SortOption: String, CaseIterable {
        case id = "ID"
        case name = "Name"
        case status = "Status"

        var icon: String {
            switch self {
            case .id: return "list.number"
            case .name: return "textformat"
            case .status: return "bolt.fill"
            }
        }
    }

    @Published var vms: [ProxmoxGuest] = []
    @Published var nodes: [ProxmoxNode] = []
    @Published var storages: [ProxmoxStorage] = []
    @Published var appState: ProxmoxServiceStatus = .stopped
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var processingVMIDs: Set<Int> = []
    @Published var resourceFilter: ResourceFilter = .all
    @Published var selectedServerId: UUID?

    @Published var sortOption: SortOption = UserPreferences.sortOption {
        didSet {
            UserPreferences.sortOption = sortOption
        }
    }

    let settings: SettingsService
    let service: any ProxmoxAPI
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsService, service: any ProxmoxAPI = ProxmoxAPIClient()) {
        self.settings = settings
        self.service = service

        settings.objectWillChange
            .sink { [weak self] _ in
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    var filteredVMs: [ProxmoxGuest] {
        var candidates = vms

        if !searchText.isEmpty {
            candidates = candidates.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }

        switch resourceFilter {
        case .all:
            break
        case .vm:
            candidates = candidates.filter(\.isVirtualMachine)
        case .lxc:
            candidates = candidates.filter(\.isContainer)
        }

        switch sortOption {
        case .id:
            candidates.sort { $0.vmid < $1.vmid }
        case .name:
            candidates.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .status:
            candidates.sort {
                if $0.isRunning != $1.isRunning {
                    return $0.isRunning
                }
                return $0.vmid < $1.vmid
            }
        }

        return candidates
    }

    var clusterStats: ProxmoxNode? {
        guard !nodes.isEmpty else { return nil }

        let totalCores = nodes.reduce(0.0) { $0 + ($1.maxcpu ?? 0) }
        let usedCores = nodes.reduce(0.0) { $0 + (($1.cpu ?? 0) * ($1.maxcpu ?? 0)) }

        let totalMem = nodes.reduce(0) { $0 + ($1.mem ?? 0) }
        let maxMem = nodes.reduce(0) { $0 + ($1.maxmem ?? 0) }

        let totalDisk = storages.reduce(0) { $0 + ($1.disk ?? 0) }
        let maxDisk = storages.reduce(0) { $0 + ($1.maxdisk ?? 0) }

        return ProxmoxNode(
            node: "Datacenter",
            status: nodes.contains(where: { $0.isOnline }) ? "online" : "offline",
            cpu: totalCores > 0 ? (usedCores / totalCores) : 0,
            maxcpu: totalCores,
            mem: totalMem,
            maxmem: maxMem,
            disk: totalDisk,
            maxdisk: maxDisk
        )
    }

    var selectedServer: ProxmoxServerConfig? {
        guard let selectedServerId else {
            return nil
        }
        return settings.servers.first(where: { $0.id == selectedServerId })
    }
}

private enum UserPreferences {
    private static let sortOptionKey = "SortOption"

    static var sortOption: ProxmoxViewModel.SortOption {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: sortOptionKey),
                  let option = ProxmoxViewModel.SortOption(rawValue: rawValue) else {
                return .id
            }
            return option
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: sortOptionKey)
        }
    }
}
