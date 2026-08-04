import Foundation
import UserNotifications

final class NotificationManager: NSObject, Sendable {
    static let shared = NotificationManager()

    private static let isNotificationCenterAvailable: Bool = {
        let bundle = Bundle.main
        let isBundledApp = bundle.bundleURL.pathExtension == "app"
        return isBundledApp && bundle.bundleIdentifier != nil
    }()

    var isAvailable: Bool {
        Self.isNotificationCenterAvailable
    }

    override private init() {
        super.init()
    }

    func requestPermission() async -> Bool {
        guard let center = configuredNotificationCenter() else {
            return false
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func sendNotification(title: String, body: String) {
        guard let center = configuredNotificationCenter() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func configuredNotificationCenter() -> UNUserNotificationCenter? {
        guard Self.isNotificationCenterAvailable else {
            return nil
        }

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        return center
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
