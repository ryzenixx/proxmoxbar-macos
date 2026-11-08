import SwiftUI

struct MenuBarContentRow: View {
    @Bindable var preference: MenuBarPreference

    var body: some View {
        HStack(spacing: 10) {
            Text("Menu Bar Shows")
                .font(.callout)
            Spacer(minLength: 8)
            Picker("Menu Bar Shows", selection: $preference.content) {
                ForEach(MenuBarPreference.Content.allCases, id: \.self) { content in
                    Text(content.label).tag(content)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
