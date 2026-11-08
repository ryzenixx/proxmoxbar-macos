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

    var settledStatus: GuestStatus? {
        switch self {
        case .start, .resume: .running
        case .shutdown, .stop: .stopped
        case .suspend: .paused
        case .reboot, .reset: nil
        }
    }

    var isForceful: Bool {
        switch self {
        case .stop, .reset: true
        case .start, .shutdown, .reboot, .suspend, .resume: false
        }
    }
}
