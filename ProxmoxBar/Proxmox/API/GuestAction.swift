import Foundation

enum GuestAction: String, Hashable, Sendable, CaseIterable {
    case start
    case shutdown
    case reboot
    case stop
    case reset
    case suspend
    case resume

    var pathComponent: String {
        rawValue
    }

    var label: String {
        switch self {
        case .start: "Start"
        case .shutdown: "Shut Down"
        case .reboot: "Restart"
        case .stop: "Force Stop"
        case .reset: "Force Reset"
        case .suspend: "Suspend"
        case .resume: "Resume"
        }
    }

    var isForceful: Bool {
        switch self {
        case .stop, .reset: true
        case .start, .shutdown, .reboot, .suspend, .resume: false
        }
    }

    var expectedStatus: GuestStatus? {
        switch self {
        case .start, .resume: .running
        case .shutdown, .stop: .stopped
        case .suspend: .paused
        case .reboot, .reset: nil
        }
    }
}
