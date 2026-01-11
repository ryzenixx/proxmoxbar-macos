import SwiftUI
import Combine
import AppKit

@MainActor
class ProxmoxViewModel: ObservableObject {
    @Published var vms: [ProxmoxVM] = []
    @Published var appState: ProxmoxServiceStatus = .stopped
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var isRefreshing: Bool = false
    
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
    
    @Published var resourceFilter: ResourceFilter = .all

    @Published var selectedServerId: UUID? = nil
    
    private var settings: SettingsService
    private var cancellables = Set<AnyCancellable>()
    
    private var isActionInProgress = false
    private let service = ProxmoxService()
    
    init(settings: SettingsService) {
        self.settings = settings
        
        settings.objectWillChange
            .sink { [weak self] _ in
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    var filteredVMs: [ProxmoxVM] {
        var result = vms
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch resourceFilter {
        case .all:
            break
        case .vm:
            result = result.filter { $0.type == "qemu" }
        case .lxc:
            result = result.filter { $0.type == "lxc" }
        }
        
        return result
    }
    
    func loadData() async {
        guard !isActionInProgress else { return }
        
        await MainActor.run {
            if self.selectedServerId == nil || !self.settings.servers.contains(where: { $0.id == self.selectedServerId }) {
                self.selectedServerId = self.settings.servers.first?.id
            }
        }
        
        guard let serverId = selectedServerId,
              let server = settings.servers.first(where: { $0.id == serverId }) else {
             await MainActor.run {
                self.vms = []
                self.appState = .stopped
                if self.settings.servers.isEmpty {
                    self.errorMessage = nil // Handled by empty state UI
                } else {
                     self.errorMessage = "Select a server."
                }
            }
            return
        }
        
        await MainActor.run {
            if case .running = appState {
            } else {
                appState = .loading("LOADING...")
            }
            errorMessage = nil
        }
        
        do {
            let (status, vms) = try await service.refreshData(url: server.url, authHeader: server.authHeader)
            
            let taggedVMs = vms.map { vm -> ProxmoxVM in
                var newVM = vm
                newVM.serverId = server.id
                return newVM
            }
            .sorted { $0.vmid < $1.vmid }
            
            await MainActor.run {
                self.appState = status
                self.vms = taggedVMs
            }
        } catch {
            await MainActor.run {
                self.appState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleVMState(_ vm: ProxmoxVM) async {
        guard let serverId = vm.serverId,
              let server = settings.servers.first(where: { $0.id == serverId }) else { return }
        
        isActionInProgress = true
        defer { isActionInProgress = false }
        
        let action = vm.isRunning ? "shutdown" : "start"
        
        do {
            try await service.performNodeAction(
                node: vm.node,
                vmid: vm.vmid,
                type: vm.type,
                action: action,
                url: server.url,
                authHeader: server.authHeader
            )
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await loadData()
        } catch {
            await MainActor.run {
                self.errorMessage = "Action failed: \(error.localizedDescription)"
            }
        }
    }

}
