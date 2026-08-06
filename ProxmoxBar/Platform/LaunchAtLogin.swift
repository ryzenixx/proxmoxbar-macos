import Foundation
import Observation

@MainActor
@Observable
final class LaunchAtLogin {
    enum Status: Hashable, Sendable {
        case enabled
        case disabled
        case requiresApproval
        case unknown
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

    var note: String? {
        if let failure { return failure }
        guard status == .requiresApproval else { return nil }
        return "macOS is waiting for your approval in Login Items."
    }

    var isNoteAProblem: Bool {
        failure != nil
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
