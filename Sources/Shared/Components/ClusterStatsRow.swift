import SwiftUI

struct ClusterStatsRow: View {
    let node: ProxmoxNode
    
    var body: some View {
        if node.isOnline {
            HStack(spacing: 8) {
                StatItem(icon: "cpu", value: node.cpuUsage, label: node.cpuUsageFormatted, color: getUsageColor(node.cpuUsage))
                StatItem(icon: "memorychip", value: node.memUsage, label: node.memUsageFormatted, color: getUsageColor(node.memUsage))
                StatItem(icon: "internaldrive", value: node.diskUsage, label: node.diskUsageFormatted, color: getUsageColor(node.diskUsage))
            }
            .padding(8)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(6)
        }
    }
    
    private func getUsageColor(_ value: Double) -> Color {
        if value >= 0.90 {
            return .red
        } else if value >= 0.75 {
            return .orange
        } else {
            return .secondary
        }
    }
}

private struct StatItem: View {
    let icon: String
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(color.opacity(0.2))
                        
                        Capsule()
                            .fill(color)
                            .frame(width: max(0, min(geometry.size.width * CGFloat(value), geometry.size.width)))
                    }
                }
                .frame(height: 3)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
