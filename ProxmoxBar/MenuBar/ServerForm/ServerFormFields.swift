import SwiftUI

struct ServerFormFields: View {
    @Bindable var model: ServerFormModel
    let submitTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Server")
                .padding(.bottom, 5)
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
                .padding(.bottom, 5)
            FieldGroup {
                FormRow(label: "Token ID", hint: "user@realm!name", text: $model.tokenIdentifier)
                Divider()
                FormRow(
                    label: "Secret",
                    hint: model.isEditing ? "unchanged" : "",
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

            submitButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var reassurance: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "lock.fill")
                .frame(width: 13)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text(secretNote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let guide = AppLinks.tokenGuide {
                    HelpLink("How to create a token", destination: guide)
                }
            }
        }
        .font(.caption)
    }

    private var secretNote: String {
        model.isEditing
            ? "Leave the secret blank to keep the one already in your keychain."
            : "Proxmox shows the secret once, when the token is created. "
                + "It goes straight to your keychain."
    }

    private var submitButton: some View {
        Button {
            Task { await model.connect() }
        } label: {
            Group {
                if model.isChecking {
                    ProgressView().controlSize(.small)
                } else {
                    Text(submitTitle)
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

struct SectionLabel: View {
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
    }
}

struct FieldGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
            .clipShape(.rect(cornerRadius: 10))
    }
}

struct FormRow: View {
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

struct ErrorNote: View {
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
