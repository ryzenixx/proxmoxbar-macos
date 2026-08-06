import SwiftUI

struct SettingsPage: View {
    @Environment(PanelRouter.self) private var router
    @Environment(ServerStore.self) private var store
    @Environment(MenuBarPreference.self) private var menuBar

    @State private var editor: ServerFormModel?
    @State private var removalError: String?
    @State private var launchAtLogin = LaunchAtLogin()

    private var title: String {
        guard let editor else { return PanelPage.settings.title }
        if case .awaitingTrust = editor.phase { return "Check the Certificate" }
        return "Edit Server"
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: title, onBack: back)
            if let editor {
                edit(with: editor)
            } else {
                sections
            }
        }
    }

    private func back() {
        guard let editor else {
            router.goBack()
            return
        }
        if case .awaitingTrust = editor.phase {
            editor.cancelTrust()
            return
        }
        self.editor = nil
    }

    @ViewBuilder
    private func edit(with editor: ServerFormModel) -> some View {
        if case .awaitingTrust(let certificate, let problems) = editor.phase {
            CertificateApprovalView(
                certificate: certificate,
                problems: problems,
                onTrust: { Task { await editor.trustPresentedCertificate() } },
                onCancel: { editor.cancelTrust() }
            )
        } else {
            ServerFormFields(model: editor, submitTitle: "Save")
                .onChange(of: editor.phase) { _, phase in
                    if phase == .saved { self.editor = nil }
                }
        }
    }

    private var sections: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    serversSection
                    generalSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            footer
        }
        .task { launchAtLogin.refresh() }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionLabel("General")
            FieldGroup {
                MenuBarContentRow(preference: menuBar)
                Divider()
                LaunchAtLoginRow(launch: launchAtLogin)
            }
        }
    }

    private var serversSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                SectionLabel("Servers")
                Spacer(minLength: 8)
                PanelIconButton(symbol: "plus", title: "Add a server") {
                    router.go(to: .addServer)
                }
            }
            FieldGroup {
                if store.servers.isEmpty {
                    emptyRow
                } else {
                    ForEach(store.servers) { configuration in
                        if configuration.id != store.servers.first?.id {
                            Divider()
                        }
                        ServerRow(
                            configuration: configuration,
                            needsToken: store.needsToken(configuration.id),
                            onEdit: { startEditing(configuration) },
                            onRemove: { remove(configuration) }
                        )
                    }
                }
            }
            if let removalError {
                ErrorNote(message: removalError)
                    .padding(.top, 4)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 7) {
            Text("\(AppInfo.name) \(AppInfo.versionSummary)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            HStack(spacing: 16) {
                if let issues = AppLinks.issues {
                    HelpLink(
                        "Report a problem",
                        symbol: "exclamationmark.bubble",
                        destination: issues
                    )
                }
                if let support = AppLinks.support {
                    HelpLink("Support the work", symbol: "heart", destination: support)
                }
            }
            .font(.footnote.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var emptyRow: some View {
        Text("No servers yet")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
    }

    private func startEditing(_ configuration: ServerConfiguration) {
        removalError = nil
        editor = ServerFormModel(
            mode: .editing(configuration),
            api: ProxmoxAPIClient(),
            store: store
        )
    }

    private func remove(_ configuration: ServerConfiguration) {
        do {
            removalError = nil
            try store.remove(configuration.id)
        } catch {
            removalError = "The server was removed but its secret stayed in the keychain."
        }
    }
}
