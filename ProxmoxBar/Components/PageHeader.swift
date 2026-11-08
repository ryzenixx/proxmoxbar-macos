import SwiftUI

struct PageHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.backward")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Text(title)
                .font(.headline)
            Spacer()
            PanelCommands()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
