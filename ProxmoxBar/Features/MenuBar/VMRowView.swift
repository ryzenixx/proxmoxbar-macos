import SwiftUI
import ProxmoxCore

struct VMRowView: View {
    let vm: ProxmoxGuest
    @ObservedObject var viewModel: ProxmoxViewModel

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            icon
            details
            Spacer()
            actions
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { viewModel.openVMInBrowser(vm) }
        .help("Open in Web Browser")
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(vm.isRunning ? Color.adaptiveGreen.opacity(0.1) : Color.gray.opacity(0.1))
                .frame(width: 28, height: 28)

            Image(systemName: vm.type == "lxc" ? "cube.box" : "display")
                .font(.system(size: 12))
                .foregroundColor(vm.isRunning ? .adaptiveGreen : .gray)
                .frame(width: 14)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(vm.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text("(\(vm.node))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Text("\(vm.vmid)")
                    .font(.system(size: 10, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(4)

                Text(vm.status.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(vm.isRunning ? .adaptiveGreen : .secondary)

                if vm.isRunning {
                    runningUsageIndicators
                }
            }
        }
    }

    private var runningUsageIndicators: some View {
        Group {
            let cpuValue = vm.cpu ?? 0
            let memoryValue = vm.memoryRatio

            Text("•")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))

            Image(systemName: "cpu")
                .font(.system(size: 10))
                .foregroundColor(usageColor(for: cpuValue))
            Text(vm.cpuUsage)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(usageColor(for: cpuValue))

            Image(systemName: "memorychip")
                .font(.system(size: 10))
                .foregroundColor(usageColor(for: memoryValue))
                .padding(.leading, 4)
            Text(vm.memUsage)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(usageColor(for: memoryValue))

            if vm.type != "qemu", let diskRatio = vm.diskRatio {
                Image(systemName: "internaldrive")
                    .font(.system(size: 10))
                    .foregroundColor(usageColor(for: diskRatio))
                    .padding(.leading, 4)
                Text(vm.diskUsage)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(usageColor(for: diskRatio))
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if viewModel.processingVMIDs.contains(vm.vmid) {
            if #available(macOS 15.0, *) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .symbolEffect(.rotate, options: .repeating)
                    .frame(width: 20, height: 20)
            } else {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 20, height: 20)
            }
        } else {
            HStack(spacing: 6) {
                if vm.isRunning {
                    Button {
                        Task { await viewModel.restartVM(vm) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.adaptiveOrange)
                            .frame(width: 20, height: 20)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Restart")
                }

                Button {
                    Task { await viewModel.toggleVMState(vm) }
                } label: {
                    Image(systemName: vm.isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(vm.isRunning ? .adaptiveRed : .adaptiveGreen)
                        .frame(width: 20, height: 20)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(vm.isRunning ? "Stop (Shutdown)" : "Start")
            }
        }
    }

    private func usageColor(for value: Double) -> Color {
        if value >= 0.95 {
            return .adaptiveRed
        }
        if value >= 0.8 {
            return .adaptiveOrange
        }
        return .primary
    }
}
