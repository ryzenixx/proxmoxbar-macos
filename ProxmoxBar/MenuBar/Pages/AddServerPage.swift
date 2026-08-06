import SwiftUI

struct AddServerPage: View {
    @Environment(PanelRouter.self) private var router
    @Environment(ServerStore.self) private var store

    @State private var model: AddServerModel?

    private var title: String {
        switch model?.phase {
        case .awaitingTrust: "Check the Certificate"
        case .added: "Server Added"
        default: PanelPage.addServer.title
        }
    }

    private func back() {
        if case .awaitingTrust = model?.phase {
            model?.cancelTrust()
            return
        }
        router.goBack()
    }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: title) {
                back()
            }
            if let model {
                step(for: model)
            }
        }
        .task {
            guard model == nil else { return }
            model = AddServerModel(api: ProxmoxAPIClient(), store: store)
        }
    }

    @ViewBuilder
    private func step(for model: AddServerModel) -> some View {
        if case .awaitingTrust(let certificate, let problems) = model.phase {
            CertificateApprovalView(
                certificate: certificate,
                problems: problems,
                onTrust: { Task { await model.trustPresentedCertificate() } },
                onCancel: { model.cancelTrust() }
            )
        } else if model.phase == .added {
            ServerConnectedView(
                name: model.addedName,
                version: model.version,
                summary: model.summary,
                onDone: { router.reset() }
            )
        } else {
            AddServerForm(model: model)
        }
    }
}

private struct AddServerForm: View {
    @Bindable var model: AddServerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Server")
            FieldGroup {
                FormRow(label: "Name", hint: "my server", text: $model.name)
                Divider()
                FormRow(
                    label: "Address",
                    hint: "https://192.168.1.1:8006",
                    text: $model.address,
                    isValid: model.hasUsableAddress
                )
            }

            SectionLabel("Access")
                .padding(.top, 18)
            FieldGroup {
                FormRow(label: "Token ID", hint: "user@realm!name", text: $model.tokenIdentifier)
                Divider()
                FormRow(
                    label: "Secret",
                    hint: "",
                    text: $model.secret,
                    isSecret: true
                )
            }

            reassurance
                .padding(.top, 10)

            if case .failed(let message) = model.phase {
                ErrorNote(message: message)
                    .padding(.top, 12)
            }

            Spacer(minLength: 12)

            connectButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var reassurance: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "lock.fill")
                .frame(width: 13)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text(
                    "Proxmox shows the secret once, when the token is created. "
                        + "It goes straight to your keychain."
                )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                if let guide = WelcomeLinks.tokenGuide {
                    HelpLink("How to create a token", destination: guide)
                }
            }
        }
        .font(.caption)
    }

    private var connectButton: some View {
        Button {
            Task { await model.connect() }
        } label: {
            Group {
                if model.isChecking {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Connect")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(model.canSubmit == false)
        .keyboardShortcut(.defaultAction)
    }
}

private struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.tertiary)
            .tracking(0.6)
            .padding(.leading, 2)
            .padding(.bottom, 5)
    }
}

private struct FieldGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
    }
}

private struct FormRow: View {
    let label: String
    let hint: String
    @Binding var text: String
    var isSecret = false
    var isValid = false

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Group {
                if isSecret {
                    SecureField(hint, text: $text)
                } else {
                    TextField(hint, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(.callout)
            if isValid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

private struct ErrorNote: View {
    let message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption)
        .foregroundStyle(.red)
    }
}
