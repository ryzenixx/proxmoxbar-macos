import Foundation

enum GuestStatus: Hashable, Sendable {
    case running
    case stopped
    case paused
    case suspended
    case suspendedToDisk
    case unknown(String)

    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "running": self = .running
        case "stopped": self = .stopped
        case "paused", "prelaunch": self = .paused
        case "suspended": self = .suspended
        default: self = .unknown(rawValue)
        }
    }

    var isRunning: Bool {
        self == .running
    }

    var label: String {
        switch self {
        case .running: "Running"
        case .stopped: "Stopped"
        case .paused: "Paused"
        case .suspended, .suspendedToDisk: "Suspended"
        case .unknown(let raw): raw.capitalized
        }
    }
}
