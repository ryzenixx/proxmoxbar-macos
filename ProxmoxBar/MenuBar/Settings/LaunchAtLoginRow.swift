import SwiftUI

struct LaunchAtLoginRow: View {
    let launch: LaunchAtLogin

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("Open at Login")
                    .font(.callout)
                Spacer(minLength: 8)
                Toggle(
                    "Open at Login",
                    isOn: Binding(
                        get: { launch.isOn },
                        set: { launch.setEnabled($0) }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if let note = launch.note {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(note)
                        .fixedSize(horizontal: false, vertical: true)
                    if launch.status == .requiresApproval {
                        Button("Open Login Items") { launch.openSystemSettings() }
                            .buttonStyle(.link)
                    }
                }
                .font(.caption)
                .foregroundStyle(launch.isNoteAProblem ? .red : .secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
    }
}
