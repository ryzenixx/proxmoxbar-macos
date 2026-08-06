import Foundation
import Observation

@MainActor
@Observable
final class LaunchAtLogin {
    enum Status: Hashable, Sendable {
        case enabled
        case disabled
        case requiresApproval
        case unavailable
    }

    private(set) var status: Status = .disabled
    private(set) var failure: String?

    @ObservationIgnored private let controller: any LoginItemController

    init(controller: any LoginItemController = SystemLoginItem()) {
        self.controller = controller
        status = controller.status
    }

    var isOn: Bool {
        status == .enabled || status == .requiresApproval
    }

    var isAvailable: Bool {
        status != .unavailable
    }

    var note: String? {
        if let failure { return failure }
        switch status {
        case .requiresApproval:
            return "macOS is waiting for your approval in Login Items."
        case .unavailable:
            return "Move ProxmoxBar to your Applications folder to use this."
        case .enabled, .disabled:
            return nil
        }
    }

    var isNoteAProblem: Bool {
        failure != nil || status == .unavailable
    }

    func refresh() {
        status = controller.status
    }

    func setEnabled(_ enabled: Bool) {
        failure = nil
        do {
            if enabled {
                try controller.register()
            } else {
                try controller.unregister()
            }
        } catch {
            failure = error.localizedDescription
        }
        refresh()
    }

    func openSystemSettings() {
        controller.openSystemSettings()
    }
}
