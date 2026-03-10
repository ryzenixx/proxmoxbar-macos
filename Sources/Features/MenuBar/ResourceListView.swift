import SwiftUI

struct ResourceListView: View {
    @ObservedObject var viewModel: ProxmoxViewModel
    @ObservedObject var settings: SettingsService
    @Binding var currentScreen: MenuBarView.Screen

    var body: some View {
        if viewModel.filteredVMs.isEmpty {
            ResourceEmptyStateView(
                viewModel: viewModel,
                settings: settings,
                currentScreen: $currentScreen
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    HStack {
                        Text("\(viewModel.filteredVMs.count) \(viewModel.filteredVMs.count == 1 ? "RESOURCE" : "RESOURCES")")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    ForEach(Array(viewModel.filteredVMs.enumerated()), id: \.element.id) { index, vm in
                        VMRowView(vm: vm, viewModel: viewModel)
                        if index < viewModel.filteredVMs.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
    }
}

private struct ResourceEmptyStateView: View {
    @ObservedObject var viewModel: ProxmoxViewModel
    @ObservedObject var settings: SettingsService
    @Binding var currentScreen: MenuBarView.Screen

    var body: some View {
        VStack {
            if settings.servers.isEmpty {
                Text("No server found")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)

                Button("Add a Server") {
                    withAnimation { currentScreen = .settings }
                }
                .padding()

                Spacer()
            } else if let fullError = viewModel.errorMessage {
                serverErrorState(for: fullError)
                Spacer()
            } else {
                Spacer()
                Text("No VMs found")
                    .foregroundColor(.secondary)
                Spacer()

                if viewModel.searchText.isEmpty {
                    missingPermissionsHint
                }
            }
        }
    }

    private func serverErrorState(for fullError: String) -> some View {
        let parts = fullError.components(separatedBy: ": ")
        let title = parts.count > 1 ? parts[0] : "Error"
        let description = parts.count > 1 ? parts.dropFirst().joined(separator: ": ") : fullError

        return VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 22))
                .foregroundColor(.red)
                .padding(.bottom, 4)

            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 40)
    }

    private var missingPermissionsHint: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.adaptiveOrange)
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text("Missing Resources?")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text("Ensure you have followed the **Permission & Security** guide in the [README](https://github.com/ryzenixx/proxmoxbar-macos?tab=readme-ov-file#-permissions--security) to configure your API Token correctly.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.adaptiveOrange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.adaptiveOrange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}
