import Foundation
import AppKit
import ProxmoxCore

extension ProxmoxViewModel {
    func loadData() async {
        synchronizeSelectedServer()

        guard let server = selectedServer else {
            vms = []
            appState = .stopped
            errorMessage = settings.servers.isEmpty ? nil : "Select a server."
            return
        }

        if case .running = appState {} else {
            appState = .loading("LOADING...")
        }
        errorMessage = nil

        do {
            let snapshot = try await service.snapshot(
                url: server.url,
                authHeader: server.authHeader
            )
            let taggedVMs = tag(vms: snapshot.guests, with: server.id)

            appState = .running
            if settings.enableNotifications {
                notifyStateChanges(from: self.vms, to: taggedVMs)
            }
            self.vms = taggedVMs
            self.nodes = snapshot.nodes
            self.storages = snapshot.storages
        } catch is CancellationError {
            return
        } catch {
            appState = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            vms = []
            nodes = []
            storages = []
        }
    }

    func toggleVMState(_ vm: ProxmoxGuest) async {
        await performAction(vm.isRunning ? .shutdown : .start, on: vm, verifyFinalStatus: true)
    }

    func restartVM(_ vm: ProxmoxGuest) async {
        await performAction(.reboot, on: vm, verifyFinalStatus: false)
    }

    func openVMInBrowser(_ vm: ProxmoxGuest) {
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

    func tag(vms: [ProxmoxGuest], with serverId: UUID) -> [ProxmoxGuest] {
        vms.map { vm in
            var tagged = vm
            tagged.serverId = serverId
            return tagged
        }
        .sorted { $0.vmid < $1.vmid }
    }

    func performAction(_ action: GuestAction, on vm: ProxmoxGuest, verifyFinalStatus: Bool) async {
        guard let serverId = vm.serverId,
              let server = settings.servers.first(where: { $0.id == serverId }) else {
            return
        }

        processingVMIDs.insert(vm.vmid)
        defer { processingVMIDs.remove(vm.vmid) }

        do {
            let upid = try await service.performGuestAction(
                action,
                node: vm.node,
                vmid: vm.vmid,
                type: vm.type,
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
                await waitForFinalStatus(for: vm, on: server)
            }

            await loadData()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "\(action.rawValue.capitalized) failed: \(error.localizedDescription)"
        }
    }

    func waitForFinalStatus(for vm: ProxmoxGuest, on server: ProxmoxServerConfig) async {
        let targetStatus = vm.isRunning ? "stopped" : "running"

        for _ in 0..<30 {
            if Task.isCancelled { return }

            let status = try? await service.guestStatus(
                node: vm.node,
                vmid: vm.vmid,
                type: vm.type,
                url: server.url,
                authHeader: server.authHeader
            )

            if status?.status == targetStatus { return }

            try? await Task.sleep(for: .seconds(1))
        }
    }

    func notifyStateChanges(from oldVMs: [ProxmoxGuest], to newVMs: [ProxmoxGuest]) {
        for vm in newVMs {
            guard let oldVM = oldVMs.first(where: { $0.id == vm.id }),
                  oldVM.status != vm.status else {
                continue
            }

            let status = vm.isRunning ? "Running" : "Stopped"
            NotificationManager.shared.sendNotification(
                title: "\(vm.displayName) (\(vm.vmid))",
                body: "is now \(status)."
            )
        }
    }
}
