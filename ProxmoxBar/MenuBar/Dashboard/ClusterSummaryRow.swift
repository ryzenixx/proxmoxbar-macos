import SwiftUI

struct ClusterSummaryRow: View {
    let state: ClusterState
    let isStale: Bool

    var body: some View {
        VStack(spacing: 8) {
            headline
            gauges
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var headline: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(healthTint)
                .frame(width: 6, height: 6)
            Text(isStale ? "Not responding" : nodeSummary)
            Spacer(minLength: 8)
            Text(guestSummary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .help(isStale ? "Showing the last values received." : "")
        .accessibilityElement(children: .combine)
    }

    private var gauges: some View {
        HStack(spacing: 12) {
            UsageGauge(
                symbol: "cpu",
                label: "CPU",
                value: state.cpuUsage,
                detail: coreSummary
            )
            UsageGauge(
                symbol: "memorychip",
                label: "Memory",
                value: state.memory?.ratio,
                detail: state.memory?.summary
            )
            UsageGauge(
                symbol: "internaldrive",
                label: "Storage",
                value: state.storage?.ratio,
                detail: state.storage?.summary
            )
        }
        .padding(10)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var coreSummary: String? {
        let cores = state.totalCores
        guard cores > 0 else { return nil }
        return "\(cores) \(cores == 1 ? "core" : "cores")"
    }

    private var healthTint: Color {
        guard !isStale else { return .red }
        guard !state.nodes.isEmpty else { return .secondary }
        return state.onlineNodes == state.nodes.count ? .green : .orange
    }

    private var nodeSummary: String {
        let total = state.nodes.count
        let unit = total == 1 ? "node" : "nodes"
        guard state.onlineNodes != total else { return "\(total) \(unit)" }
        return "\(state.onlineNodes) of \(total) \(unit) online"
    }

    private var guestSummary: String {
        "\(state.runningGuests) of \(state.guests.count) running"
    }
}

private struct UsageGauge: View {
    let symbol: String
    let label: String
    let value: Double?
    let detail: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 13)
            VStack(alignment: .leading, spacing: 3) {
                Text(percentage)
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                UsageMeter(value: value ?? 0)
            }
        }
        .help(help)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(help)
    }

    private var percentage: String {
        guard let value else { return "—" }
        return "\(Int((value * 100).rounded()))%"
    }

    private var help: String {
        guard let detail else { return "\(label) \(percentage)" }
        return "\(label) \(percentage) · \(detail)"
    }
}
