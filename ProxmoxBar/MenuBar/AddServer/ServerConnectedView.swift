import SwiftUI

struct ServerConnectedView: View {
    let name: String
    let version: ServerVersion?
    let summary: ClusterState?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.green)

            Text("Connected to \(name)")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Text("ProxmoxBar can now watch this cluster and power its machines.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)

            facts
                .padding(.top, 22)

            Spacer(minLength: 12)

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var facts: some View {
        VStack(spacing: 0) {
            if let version {
                Fact(label: "Proxmox VE", value: version.version)
                Divider()
            }
            if let summary {
                Fact(label: "Nodes", value: "\(summary.nodes.count)")
                Divider()
                Fact(label: "Machines", value: "\(summary.guests.count)")
                Divider()
                Fact(label: "Storage", value: "\(summary.storages.count)")
            }
        }
        .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 10))
    }
}

private struct Fact: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
