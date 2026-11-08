import SwiftUI
import UserNotifications

struct NotificationsRow: View {
    let notifications: AppNotifications

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("Notifications")
                    .font(.callout)
                Spacer(minLength: 8)
                Toggle(
                    "Notifications",
                    isOn: Binding(
                        get: { notifications.isEnabled },
                        set: { wants in
                            if wants {
                                Task { await notifications.enable() }
                            } else {
                                notifications.disable()
                            }
                        }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(!notifications.isAvailable)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
        }
    }

    private var note: String? {
        if !notifications.isAvailable {
            return "Unavailable in this build."
        }
        if notifications.authorization == .denied {
            return "Turn ProxmoxBar on in System Settings, Notifications."
        }
        return nil
    }
}
