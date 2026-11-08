import SwiftUI

struct PanelIconButton: View {
    let symbol: String
    let title: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? Color.primary.opacity(0.1) : .clear)
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(title)
        .accessibilityLabel(title)
    }
}
