import SwiftUI
import Combine
import AppKit

@MainActor
class ProxmoxViewModel: ObservableObject {
    @Published var vms: [ProxmoxVM] = []
    @Published var nodes: [ProxmoxNode] = []
    @Published var storages: [ProxmoxStorage] = []
    @Published var appState: ProxmoxServiceStatus = .stopped
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var isRefreshing: Bool = false
    @Published var processingVMIDs: Set<Int> = []
    
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
    
    var clusterStats: ProxmoxNode? {
        guard !nodes.isEmpty else { return nil }
        
        let totalCores = nodes.reduce(0.0) { $0 + ($1.maxcpu ?? 0) }
        let totalUsedCores = nodes.reduce(0.0) { $0 + ($1.cpu ?? 0) * ($1.maxcpu ?? 0) }
        let totalCpu = totalCores > 0 ? totalUsedCores / totalCores : 0
        
        let totalMem = nodes.reduce(0) { $0 + ($1.mem ?? 0) }
        let totalMaxMem = nodes.reduce(0) { $0 + ($1.maxmem ?? 0) }
        
        let totalDisk = storages.reduce(0) { $0 + ($1.disk ?? 0) }
        let totalMaxDisk = storages.reduce(0) { $0 + ($1.maxdisk ?? 0) }
        
        let isOnline = nodes.contains { $0.isOnline }
        
        return ProxmoxNode(
            node: "Datacenter",
            status: isOnline ? "online" : "offline",
            cpu: totalCpu,
            maxcpu: totalCores,
            mem: totalMem,
            maxmem: totalMaxMem,
            disk: totalDisk,
            maxdisk: totalMaxDisk
        )
    }
    
    func loadData() async {
        
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
            let (status, nodes, storages, vms) = try await service.refreshData(url: server.url, authHeader: server.authHeader)
            
            let taggedVMs = vms.map { vm -> ProxmoxVM in
                var newVM = vm
                newVM.serverId = server.id
                return newVM
            }
            .sorted { $0.vmid < $1.vmid }
            
            await MainActor.run {
                self.appState = status
                self.vms = taggedVMs
                self.nodes = nodes
                self.storages = storages
            }
        } catch {
            await MainActor.run {
                self.appState = .error(error.localizedDescription)
                self.errorMessage = error.localizedDescription
                
                // Clear data to prevent displaying stale information from previous server
                self.vms = []
                self.nodes = []
                self.storages = []
            }
        }
    }
    
    func toggleVMState(_ vm: ProxmoxVM) async {
        let action = vm.isRunning ? "shutdown" : "start"
        await executeAction(action, on: vm, verifyStatusChange: true)
    }
    
    func restartVM(_ vm: ProxmoxVM) async {
        await executeAction("reboot", on: vm, verifyStatusChange: false)
    }
    
    private func executeAction(_ action: String, on vm: ProxmoxVM, verifyStatusChange: Bool) async {
        guard let serverId = vm.serverId,
              let server = settings.servers.first(where: { $0.id == serverId }) else { return }
        
        processingVMIDs.insert(vm.vmid)
        defer { processingVMIDs.remove(vm.vmid) }
        
        do {
            let upid = try await service.performNodeAction(
                node: vm.node,
                vmid: vm.vmid,
                type: vm.type,
                action: action,
                url: server.url,
                authHeader: server.authHeader
            )
            
            try await service.waitForTask(node: vm.node, upid: upid, url: server.url, authHeader: server.authHeader)
            
            if verifyStatusChange {
                await waitForFinalStatus(for: vm)
            }
            
            await loadData()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "\(action.capitalized) failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func waitForFinalStatus(for vm: ProxmoxVM) async {
        let targetStatus = vm.isRunning ? "stopped" : "running"
        for _ in 0..<30 {
            await loadData()
            if vms.first(where: { $0.vmid == vm.vmid })?.status == targetStatus { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
}
