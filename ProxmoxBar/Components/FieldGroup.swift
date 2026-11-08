import SwiftUI

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
