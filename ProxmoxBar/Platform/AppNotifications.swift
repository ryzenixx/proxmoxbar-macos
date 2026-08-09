import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class AppNotifications: StatusChangeNotifier, NotificationSwitch {
    static let enabledKey = "ProxmoxBar.notifyOnStatusChange"

    private(set) var isEnabled: Bool
    private(set) var authorization: UNAuthorizationStatus = .notDetermined

    var isAvailable: Bool {
        let bundle = Bundle.main
        return bundle.bundleURL.pathExtension == "app" && bundle.bundleIdentifier != nil
    }

    var canPost: Bool {
        guard isEnabled, isAvailable else { return false }
        return authorization == .authorized || authorization == .provisional
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let presenter = NotificationPresenter()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Self.enabledKey)
    }

    func configure() {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().delegate = presenter
        Task { await refreshAuthorization() }
    }

    func refreshAuthorization() async {
        guard isAvailable else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorization = settings.authorizationStatus
    }

    @discardableResult
    func enable() async -> Bool {
        guard isAvailable else { return false }
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .notDetermined:
            let granted =
                (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            authorization = granted ? .authorized : .denied
            setEnabled(granted)
            return granted
        case .authorized, .provisional, .ephemeral:
            authorization = status
            setEnabled(true)
            return true
        default:
            authorization = status
            setEnabled(false)
            return false
        }
    }

    func disable() {
        setEnabled(false)
    }

    func post(_ event: StatusEvent) {
        guard canPost else { return }
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func setEnabled(_ value: Bool) {
        guard value != isEnabled else { return }
        isEnabled = value
        defaults.set(value, forKey: Self.enabledKey)
    }
}

final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
