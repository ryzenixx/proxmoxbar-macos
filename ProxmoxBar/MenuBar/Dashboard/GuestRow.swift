import SwiftUI

struct GuestRow: View {
    let guest: ProxmoxGuest

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: guest.kind == .container ? "shippingbox" : "display")
                .font(.system(size: 13))
                .foregroundStyle(statusTint)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(guest.displayName)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("\(guest.vmid)")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                }
                Text(metadata)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .opacity(guest.status.isRunning ? 1 : 0.6)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(isHovered ? Color.primary.opacity(0.06) : .clear)
        .contentShape(.rect)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(guest.displayName), \(guest.kind.label) \(guest.vmid), \(metadata)"
        )
    }

    private var metadata: String {
        var parts = [guest.node]
        if guest.isTemplate {
            parts.append("Template")
        } else if guest.status.isRunning {
            parts.append("CPU \(percentage(guest.cpu))")
            parts.append("RAM \(percentage(guest.memoryUsage))")
        } else {
            parts.append(guest.status.label)
        }
        return parts.joined(separator: " · ")
    }

    private var statusTint: Color {
        guard !guest.isTemplate else { return .secondary }
        switch guest.status {
        case .running: return .green
        case .paused, .suspended: return .orange
        case .stopped, .unknown: return .secondary
        }
    }

    private func percentage(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int((value * 100).rounded()))%"
    }
}
