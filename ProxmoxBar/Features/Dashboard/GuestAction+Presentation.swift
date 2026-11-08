extension GuestAction {
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

    var symbol: String {
        switch self {
        case .start, .resume: "play.fill"
        case .shutdown: "power"
        case .reboot: "arrow.clockwise"
        case .stop: "stop.fill"
        case .reset: "exclamationmark.arrow.circlepath"
        case .suspend: "pause.fill"
        }
    }

    var progressLabel: String {
        switch self {
        case .start: "Starting…"
        case .shutdown: "Shutting down…"
        case .reboot: "Restarting…"
        case .stop: "Forcing off…"
        case .reset: "Resetting…"
        case .suspend: "Suspending…"
        case .resume: "Resuming…"
        }
    }
}
