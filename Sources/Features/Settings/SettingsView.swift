import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsService
    @ObservedObject var launchService: LaunchAtLoginService
    @ObservedObject var updaterController: UpdaterController
    var onBack: () -> Void

    @State private var activeAlert: ActiveAlert?
    @State private var draggedItem: ProxmoxServerConfig?

    enum ActiveAlert: Identifiable {
        case delete(ProxmoxServerConfig)

        var id: String {
            switch self {
            case .delete(let server):
                return "delete-\(server.id)"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsHeaderView(onBack: onBack)
            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    SettingsServersSection(
                        settings: settings,
                        draggedItem: $draggedItem,
                        onDelete: { server in activeAlert = .delete(server) }
                    )

                    SettingsGeneralSection(
                        settings: settings,
                        launchService: launchService,
                        onEnableNotifications: {
                            Task { @MainActor in
                                let granted = await NotificationManager.shared.requestPermission()
                                settings.enableNotifications = granted
                            }
                        }
                    )

                    SettingsUpdatesSection(updaterController: updaterController)
                }
                .padding(20)
            }

            Spacer()
            SettingsFooterView()
        }
        .background(CursorFixView())
        .sheet(item: $settings.activeSheet) { sheet in
            switch sheet {
            case .add:
                ServerFormView(settings: settings, existingServer: nil)
            case .edit(let server):
                ServerFormView(settings: settings, existingServer: server)
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .delete(let server):
                return Alert(
                    title: Text("Delete Server"),
                    message: Text("Are you sure you want to remove '\(server.name)'?"),
                    primaryButton: .destructive(Text("Delete")) {
                        settings.removeServer(id: server.id)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
