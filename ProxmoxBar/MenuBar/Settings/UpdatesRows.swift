import SwiftUI

struct UpdatesRows: View {
    @Bindable var updates: AppUpdates
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 10) {
            Text("Check Automatically")
                .font(.callout)
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
            Spacer(minLength: 8)
            Toggle("Check Automatically", isOn: $updates.checksAutomatically)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)

        Divider()

        HStack(spacing: 10) {
            Text("Version \(AppInfo.version)")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Button("Check Now") { updates.checkNow() }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(updates.canCheck == false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
