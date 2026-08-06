import SwiftUI

struct GuestRow: View {
    let guest: ProxmoxGuest
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
        .onChange(of: runningAction) { _, action in
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
        .disabled(guest.availableActions.isEmpty && failure == nil)
        .accessibilityLabel(
            "\(guest.displayName), \(guest.kind.label) \(guest.vmid), \(spokenStatus)")
    }

    @ViewBuilder
    private var statusLine: some View {
        if let failure, !isExpanded {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                Text(failure)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .font(.caption)
            .foregroundStyle(.red)
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
        if runningAction != nil {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.6)
                .frame(width: 14, height: 14)
        } else if !guest.availableActions.isEmpty || failure != nil {
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let failure {
                VStack(alignment: .leading, spacing: 6) {
                    Text(failure)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Dismiss") { model.dismissFailure(for: guest) }
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
                Task { await model.perform(action, on: guest) }
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
        .disabled(runningAction != nil)
    }

    private var runningAction: GuestAction? {
        model.runningActions[guest.id]
    }

    private var failure: String? {
        model.actionFailures[guest.id]
    }

    private var isDimmed: Bool {
        guest.status.isRunning == false && runningAction == nil && failure == nil
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
        if let runningAction {
            return "\(guest.node) · \(runningAction.progressLabel)"
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
        failure.map { "Failed: \($0)" } ?? metadata
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
