import SwiftUI

struct GuestRow: View {
    let guest: ProxmoxGuest
    let source: DashboardModel.Source
    let isExpanded: Bool
    let onToggle: () -> Void

    @Environment(DashboardModel.self) private var model
    @State private var isHovered = false
    @State private var pendingForce: GuestAction?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            summary
            if isExpanded {
                details
            }
        }
        .background(background)
        .onHover { isHovered = $0 }
        .onChange(of: isExpanded) { _, expanded in
            if !expanded { pendingForce = nil }
        }
        .onChange(of: actionProgress) { _, action in
            if action != nil { pendingForce = nil }
        }
    }

    private var summary: some View {
        Button(action: onToggle) {
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
                    statusLine
                }
                Spacer(minLength: 8)
                trailing
            }
            .opacity(isDimmed ? 0.6 : 1)
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(guest.availableActions.isEmpty && notice == nil)
        .accessibilityLabel(
            "\(guest.displayName), \(guest.kind.label) \(guest.vmid), \(spokenStatus)")
    }

    @ViewBuilder
    private var statusLine: some View {
        if let notice, !isExpanded {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                Text(notice.message)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .font(.caption)
            .foregroundStyle(noticeTint)
        } else {
            Text(metadata)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if actionProgress != nil {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.6)
                .frame(width: 14, height: 14)
        } else if !guest.availableActions.isEmpty || notice != nil {
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let notice {
                VStack(alignment: .leading, spacing: 6) {
                    Text(notice.message)
                        .font(.caption)
                        .foregroundStyle(noticeTint)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Dismiss") { model.dismissNotice(for: guest, from: source) }
                        .buttonStyle(.link)
                        .font(.caption)
                }
            }
            if !guest.availableActions.isEmpty {
                HStack(spacing: 6) {
                    ForEach(guest.availableActions, id: \.self, content: button)
                }
            }
        }
        .padding(.leading, 44)
        .padding(.trailing, 16)
        .padding(.bottom, 8)
    }

    private func button(for action: GuestAction) -> some View {
        let isConfirming = pendingForce == action
        return Button {
            if action.isForceful && !isConfirming {
                pendingForce = action
            } else {
                pendingForce = nil
                Task { await model.perform(action, on: guest, from: source) }
            }
        } label: {
            Label {
                Text(isConfirming ? "Really?" : action.label)
                    .font(.caption)
            } icon: {
                Image(systemName: isConfirming ? "exclamationmark.triangle.fill" : action.symbol)
                    .font(.system(size: 9))
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(action.isForceful ? .red : nil)
        .disabled(actionProgress != nil)
    }

    private var actionProgress: DashboardModel.ActionProgress? {
        model.actionProgress(for: guest, from: source)
    }

    private var notice: DashboardModel.ActionNotice? {
        model.actionNotices[guest.id]
    }

    private var noticeTint: Color {
        switch notice {
        case .taskUnconfirmed, .taskWarnings, .stateUnconfirmed: .orange
        case .failed, nil: .red
        }
    }

    private var isDimmed: Bool {
        guest.status.isRunning == false && actionProgress == nil && notice == nil
    }

    @ViewBuilder
    private var background: some View {
        if isExpanded {
            Color.primary.opacity(0.05)
        } else if isHovered {
            Color.primary.opacity(0.06)
        }
    }

    private var metadata: String {
        if let actionProgress {
            return "\(guest.node) · \(actionProgress.label)"
        }
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

    private var spokenStatus: String {
        notice?.message ?? metadata
    }

    private var statusTint: Color {
        guard !guest.isTemplate else { return .secondary }
        switch guest.status {
        case .running: return .green
        case .paused, .suspended, .suspendedToDisk: return .orange
        case .stopped, .unknown: return .secondary
        }
    }

    private func percentage(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.usagePercent)
    }
}
