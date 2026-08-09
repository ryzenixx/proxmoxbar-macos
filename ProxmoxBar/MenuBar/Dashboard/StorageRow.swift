import SwiftUI

struct StorageRow: View {
    let storage: ProxmoxStorage

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "internaldrive")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(storage.name)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let tag {
                        Text(tag)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                metadata
            }
            Spacer(minLength: 8)
            if !storage.isUnavailable, let percentage = storage.percentageText {
                Text(percentage)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(storage.isUnavailable ? 0.6 : 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(isHovered ? Color.primary.opacity(0.06) : .clear)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    @ViewBuilder
    private var metadata: some View {
        if storage.isUnavailable {
            Text("Unavailable")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 8) {
                Text(detail)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let usage = storage.usage {
                    UsageMeter(value: usage)
                        .frame(width: 44)
                }
            }
        }
    }

    private var detail: String {
        var parts: [String] = []
        if let type = storage.pluginType?.uppercased(), !type.isEmpty {
            parts.append(type)
        }
        if let capacity = storage.capacitySummary {
            parts.append(capacity)
        }
        return parts.joined(separator: " · ")
    }

    private var tag: String? {
        storage.isShared ? "shared" : storage.node
    }

    private var spoken: String {
        if storage.isUnavailable {
            return "\(storage.name), unavailable"
        }
        var parts = [storage.name]
        if let percentage = storage.percentageText { parts.append(percentage) }
        if let capacity = storage.capacitySummary { parts.append(capacity) }
        return parts.joined(separator: ", ")
    }
}
