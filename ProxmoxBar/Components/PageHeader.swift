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
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
