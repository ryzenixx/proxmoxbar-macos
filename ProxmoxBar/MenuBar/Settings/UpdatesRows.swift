import SwiftUI

struct UpdatesRows: View {
    @Bindable var updates: AppUpdates

    var body: some View {
        HStack(spacing: 10) {
            Text("Check Automatically")
                .font(.callout)
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
        .padding(.vertical, 8)
    }
}
