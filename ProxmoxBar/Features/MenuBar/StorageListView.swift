import SwiftUI
import ProxmoxCore

struct StorageListView: View {
    @ObservedObject var viewModel: ProxmoxViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(viewModel.storages.count) \(viewModel.storages.count == 1 ? "STORAGE" : "STORAGES")")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            if viewModel.storages.isEmpty {
                VStack {
                    Spacer()
                    Text("No storages found")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.storages.enumerated()), id: \.element.id) { index, storage in
                            StorageRowView(storage: storage)
                            if index < viewModel.storages.count - 1 {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct StorageRowView: View {
    let storage: ProxmoxStorage
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            icon
            details
            Spacer()
            capacity
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(storage.isAvailable ? Color.adaptiveGreen.opacity(0.1) : Color.gray.opacity(0.1))
                .frame(width: 28, height: 28)

            Image(systemName: "internaldrive")
                .font(.system(size: 12))
                .foregroundColor(storage.isAvailable ? .adaptiveGreen : .gray)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(storage.storage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text("(\(storage.node))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                if let type = storage.type {
                    Text(type.uppercased())
                        .font(.system(size: 10, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Text(storage.status.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(storage.isAvailable ? .adaptiveGreen : .secondary)
                    .fixedSize(horizontal: true, vertical: false)

                if storage.isAvailable {
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))

                            Capsule()
                                .fill(usageColor(for: storage.diskUsage))
                                .frame(width: max(0, min(geometry.size.width * CGFloat(storage.diskUsage), geometry.size.width)))
                        }
                    }
                    .frame(width: 40, height: 4)

                    Text(storage.diskUsageFormatted)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(usageColor(for: storage.diskUsage))
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }

    @ViewBuilder
    private var capacity: some View {
        if let disk = storage.disk, let maxDisk = storage.maxdisk {
            Text("\(formatBytes(disk)) / \(formatBytes(maxDisk))")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private func usageColor(for value: Double) -> Color {
        if value >= 0.9 {
            return .adaptiveRed
        }
        if value >= 0.75 {
            return .adaptiveOrange
        }
        return .primary
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
}
