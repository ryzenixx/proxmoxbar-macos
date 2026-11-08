import SwiftUI

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
