import SwiftUI
import WidgetKit

struct ServerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ServerEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemSmall:
                SmallServerView(snapshot: snapshot)
            default:
                MediumServerView(snapshot: snapshot)
            }
        } else {
            EmptyServerView()
        }
    }
}

private struct SmallServerView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ServerHeader(name: snapshot.name, reachable: snapshot.reachable)
            Spacer(minLength: 6)
            if snapshot.reachable {
                Text("\(snapshot.running)")
                    .font(.system(size: 36, weight: .semibold))
                    .monospacedDigit()
                Text(snapshot.running == 1 ? "machine running" : "machines running")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let cpu = snapshot.cpu {
                    InlineMeter(label: "CPU", value: cpu)
                        .padding(.top, 8)
                }
            } else {
                UnreachableLabel()
                Spacer()
            }
        }
    }
}

private struct MediumServerView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ServerHeader(name: snapshot.name, reachable: snapshot.reachable)
                Spacer(minLength: 8)
                if snapshot.reachable {
                    Text("\(snapshot.nodeSummary) · \(snapshot.running) running")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            if snapshot.reachable {
                HStack(alignment: .top, spacing: 14) {
                    GaugeColumn(symbol: "cpu", label: "CPU", value: snapshot.cpu)
                    GaugeColumn(symbol: "memorychip", label: "MEM", value: snapshot.memory)
                    GaugeColumn(symbol: "internaldrive", label: "DSK", value: snapshot.storage)
                }
            } else {
                UnreachableLabel()
                Spacer()
            }
        }
    }
}

private struct GaugeColumn: View {
    let symbol: String
    let label: String
    let value: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 11))
                Text(label)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(.secondary)
            Text(percentage)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            MeterBar(value: value ?? 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var percentage: String {
        guard let value else { return "—" }
        return "\(Int((value * 100).rounded()))%"
    }
}

private struct InlineMeter: View {
    let label: String
    let value: Double

    var body: some View {
        HStack(spacing: 7) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            MeterBar(value: value)
            Text("\(Int((value * 100).rounded()))%")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

private struct MeterBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                if value > 0 {
                    Capsule()
                        .fill(tint)
                        .frame(width: max(proxy.size.width * min(value, 1), 4))
                }
            }
        }
        .frame(height: 5)
    }

    private var tint: Color {
        switch value {
        case 0.9...: .red
        case 0.75...: .orange
        default: .secondary
        }
    }
}

private struct ServerHeader: View {
    let name: String
    let reachable: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "server.rack")
                .font(.caption)
                .foregroundStyle(reachable ? Color.secondary : Color.orange)
            Text(name)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

private struct UnreachableLabel: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "wifi.slash")
                .font(.caption2)
            Text("Unreachable")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.top, 6)
    }
}

private struct EmptyServerView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("No server yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension WidgetSnapshot {
    var nodeSummary: String {
        let unit = nodesTotal == 1 ? "node" : "nodes"
        if nodesOnline == nodesTotal { return "\(nodesTotal) \(unit)" }
        return "\(nodesOnline)/\(nodesTotal) \(unit)"
    }
}
