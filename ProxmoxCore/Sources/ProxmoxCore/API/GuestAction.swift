import Foundation

public enum GuestAction: String, Sendable, CaseIterable {
    case start
    case shutdown
    case reboot
}
