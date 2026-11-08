import Foundation
import Observation
import ServiceManagement

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

    init() {
        refresh()
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
        status =
            switch SMAppService.mainApp.status {
            case .enabled: .enabled
            case .notRegistered: .disabled
            case .requiresApproval: .requiresApproval
            case .notFound: .unknown
            @unknown default: .unknown
            }
    }

    func setEnabled(_ enabled: Bool) {
        failure = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            failure = error.localizedDescription
        }
        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
