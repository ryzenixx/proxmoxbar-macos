import SwiftUI

struct ServerRow: View {
    let configuration: ServerConfiguration
    let needsToken: Bool
    let onEdit: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false
    @State private var isConfirmingRemoval = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(configuration.displayName)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(needsToken ? .red : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            controls
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(isHovered ? Color.primary.opacity(0.06) : .clear)
        .contentShape(.rect)
        .onHover { hovering in
            isHovered = hovering
            if !hovering { isConfirmingRemoval = false }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if isConfirmingRemoval {
            Button("Remove", role: .destructive, action: onRemove)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            Button("Keep") { isConfirmingRemoval = false }
                .buttonStyle(.bordered)
                .controlSize(.small)
        } else {
            PanelIconButton(symbol: "pencil", title: "Edit", action: onEdit)
                .opacity(isHovered ? 1 : 0)
            PanelIconButton(symbol: "trash", title: "Remove") {
                isConfirmingRemoval = true
            }
            .opacity(isHovered ? 1 : 0)
        }
    }

    private var subtitle: String {
        guard !needsToken else { return "No token in the keychain" }
        return configuration.address
    }
}
