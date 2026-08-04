import Foundation
import AppKit

extension ProxmoxViewModel {
    func loadData() async {
        synchronizeSelectedServer()

        guard let server = selectedServer else {
            vms = []
            appState = .stopped
            errorMessage = settings.servers.isEmpty ? nil : "Select a server."
            return
        }

        if case .running = appState {
            // Keep the running indicator visible while refreshing.
        } else {
            appState = .loading("LOADING...")
        }
        errorMessage = nil

        do {
            let (status, nodes, storages, vms) = try await service.refreshData(
                url: server.url,
                authHeader: server.authHeader
            )
            let taggedVMs = tag(vms: vms, with: server.id)

            appState = status
            if settings.enableNotifications {
                notifyStateChanges(from: self.vms, to: taggedVMs)
            }
            self.vms = taggedVMs
            self.nodes = nodes
            self.storages = storages
        } catch {
            appState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            vms = []
            nodes = []
            storages = []
        }
    }

    func toggleVMState(_ vm: ProxmoxVM) async {
        let action = vm.isRunning ? "shutdown" : "start"
        await performAction(action, on: vm, verifyFinalStatus: true)
    }

    func restartVM(_ vm: ProxmoxVM) async {
        await performAction("reboot", on: vm, verifyFinalStatus: false)
    }

    func openVMInBrowser(_ vm: ProxmoxVM) {
        guard let serverId = vm.serverId,
              let server = settings.servers.first(where: { $0.id == serverId }),
              let baseURL = server.baseWebURL else {
            return
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.percentEncodedFragment = "v1:0:=\(vm.type)%2F\(vm.vmid)"

        if let url = components?.url {
            NSWorkspace.shared.open(url)
        }
    }
}

private extension ProxmoxViewModel {
    func synchronizeSelectedServer() {
        if selectedServerId == nil || !settings.servers.contains(where: { $0.id == selectedServerId }) {
            selectedServerId = settings.servers.first?.id
        }
    }

    func tag(vms: [ProxmoxVM], with serverId: UUID) -> [ProxmoxVM] {
        vms.map { vm in
            var tagged = vm
            tagged.serverId = serverId
            return tagged
        }
        .sorted { $0.vmid < $1.vmid }
    }

    func performAction(_ action: String, on vm: ProxmoxVM, verifyFinalStatus: Bool) async {
        guard let serverId = vm.serverId,
              let server = settings.servers.first(where: { $0.id == serverId }) else {
            return
        }

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

            try await service.waitForTask(
                node: vm.node,
                upid: upid,
                url: server.url,
                authHeader: server.authHeader
            )

            if verifyFinalStatus {
                await waitForFinalStatus(for: vm)
            }

            await loadData()
        } catch {
            errorMessage = "\(action.capitalized) failed: \(error.localizedDescription)"
        }
    }

    func waitForFinalStatus(for vm: ProxmoxVM) async {
        let targetStatus = vm.isRunning ? "stopped" : "running"
        for _ in 0..<30 {
            await loadData()
            if vms.first(where: { $0.vmid == vm.vmid })?.status == targetStatus {
                return
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    func notifyStateChanges(from oldVMs: [ProxmoxVM], to newVMs: [ProxmoxVM]) {
        for vm in newVMs {
            guard let oldVM = oldVMs.first(where: { $0.id == vm.id }),
                  oldVM.status != vm.status else {
                continue
            }

            let status = vm.isRunning ? "Running" : "Stopped"
            NotificationManager.shared.sendNotification(
                title: "\(vm.name) (\(vm.vmid))",
                body: "is now \(status)."
            )
        }
    }
}
