import SwiftUI
import AppKit

struct SettingsHeaderView: View {
    var onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text("Settings")
                .font(.system(size: 14, weight: .bold))

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

struct SettingsServersSection: View {
    @ObservedObject var settings: SettingsService
    @Binding var draggedItem: ProxmoxServerConfig?
    var onDelete: (ProxmoxServerConfig) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SERVERS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    settings.activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 4)

            if settings.servers.isEmpty {
                Text("No servers configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(settings.servers) { server in
                        SettingsServerRow(
                            server: server,
                            onEdit: { settings.activeSheet = .edit(server) },
                            onDelete: { onDelete(server) }
                        )
                        .onDrag {
                            draggedItem = server
                            return NSItemProvider(object: server.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: ServerReorderDropDelegate(
                                destinationItem: server,
                                servers: $settings.servers,
                                draggedItem: $draggedItem
                            )
                        )
                    }
                }
            }
        }
    }
}

private struct SettingsServerRow: View {
    let server: ProxmoxServerConfig
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.system(size: 13, weight: .medium))
                Text(server.url)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }
}

struct SettingsGeneralSection: View {
    @ObservedObject var settings: SettingsService
    @ObservedObject var launchService: LaunchAtLoginService
    var onEnableNotifications: () -> Void
    private var notificationsAvailable: Bool { NotificationManager.shared.isAvailable }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GENERAL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                launchAtLoginRow
                notificationsRow
            }
        }
    }

    private var launchAtLoginRow: some View {
        HStack {
            Image(systemName: "arrow.up.circle")
                .foregroundColor(.blue)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text("Launch at Login")
                    .font(.system(size: 13))

                Text("Start ProxmoxBar automatically when you sign in.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { launchService.isEnabled },
                set: { _ in launchService.toggle() }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }

    private var notificationsRow: some View {
        HStack {
            Image(systemName: "bell.badge")
                .foregroundColor(.orange)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text("Enable Notifications")
                    .font(.system(size: 13))

                Text(notificationsAvailable ? "Get notified when VM/LXC status changes." : "Unavailable in local executable builds.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { settings.enableNotifications },
                set: { newValue in
                    guard notificationsAvailable else {
                        settings.enableNotifications = false
                        return
                    }

                    if newValue {
                        if !settings.enableNotifications {
                            onEnableNotifications()
                        }
                    } else {
                        settings.enableNotifications = false
                    }
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .disabled(!notificationsAvailable)
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }
}

struct SettingsUpdatesSection: View {
    @ObservedObject var updaterController: UpdaterController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPDATES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            Button(action: { updaterController.checkForUpdates() }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(updaterController.canCheckForUpdates ? .primary : .secondary)
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Check for Updates")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(updaterController.canCheckForUpdates ? .primary : .secondary)

                        if updaterController.canCheckForUpdates {
                            Text("Current Version: \(AppConfig.appVersion)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Updater unavailable in this local build")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(12)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(!updaterController.canCheckForUpdates)
        }
    }
}

struct SettingsFooterView: View {
    var body: some View {
        VStack(spacing: 2) {
            Text(AppConfig.appName)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("version \(AppConfig.appVersion)")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))

            HStack(spacing: 12) {
                footerLink(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "View on GitHub",
                    color: Color(red: 0.6, green: 0.4, blue: 0.9),
                    url: "https://github.com/ryzenixx/proxmoxbar-macos"
                )

                Text("|")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.3))

                footerLink(
                    icon: "cup.and.saucer.fill",
                    title: "Buy me a coffee",
                    color: Color(red: 1.0, green: 0.37, blue: 0.0),
                    url: "https://ko-fi.com/ryzenixx"
                )
            }
            .padding(.top, 4)
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func footerLink(icon: String, title: String, color: Color, url: String) -> some View {
        Button {
            guard let destination = URL(string: url) else { return }
            NSWorkspace.shared.open(destination)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
            }
            .font(.caption2)
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
