import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsService
    @ObservedObject var launchService: LaunchAtLoginService
    @ObservedObject var updaterController: UpdaterController
    var onBack: () -> Void
    
    @State private var activeSheet: SettingsSheet?
    @State private var serverToDelete: ProxmoxServerConfig?
    
    // For Drag and Drop
    @State private var draggedItem: ProxmoxServerConfig?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text("Settings")
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("SERVERS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                activeSheet = .add
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 4)
                        
                        if settings.servers.isEmpty {
                            Text("No servers configured")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(settings.servers) { server in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(server.name)
                                                .font(.system(size: 13, weight: .medium))
                                            Text(server.url)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        
                                        Button {
                                            activeSheet = .edit(server)
                                        } label: {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.trailing, 4)
                                        
                                        Button {
                                            serverToDelete = server
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(10)
                                    .background(Color.primary.opacity(0.03))
                                    .cornerRadius(8)
                                    .onDrag {
                                        self.draggedItem = server
                                        return NSItemProvider(object: server.id.uuidString as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: DropViewDelegate(destinationItem: server, servers: $settings.servers, draggedItem: $draggedItem))
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GENERAL")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                                Text("Launch at Login")
                                    .font(.system(size: 13))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { launchService.isEnabled },
                                    set: { _ in launchService.toggle() }
                                ))
                                .labelsHidden()
                                .toggleStyle(.switch)
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Updates Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("UPDATES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        Button(action: {
                            #if !DEBUG
                            updaterController.checkForUpdates()
                            #endif
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    #if DEBUG
                                    .foregroundColor(.secondary)
                                    #else
                                    .foregroundColor(.primary)
                                    #endif
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Check for Updates")
                                        .font(.system(size: 13, weight: .medium))
                                        #if DEBUG
                                        .foregroundColor(.secondary)
                                        #else
                                        .foregroundColor(.primary)
                                        #endif
                                    
                                    #if DEBUG
                                    Text("Updater disabled in development build")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    #else
                                    Text("Current Version: \(AppConfig.appVersion)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    #endif
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(12)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        #if DEBUG
                        .disabled(true)
                        #endif
                    }
                    
                }
                .padding(20)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 2) {
                Text(AppConfig.appName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                #if DEBUG
                Text("version 0.0.0 | development build")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                #else
                Text("version \(AppConfig.appVersion) | release build")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                #endif
                
                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/ryzenixx/proxmoxbar-macos") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .font(.caption2)
                .padding(.top, 2)
            }
            .padding(.bottom, 16)
        }
        .background(CursorFixView())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                ServerFormView(settings: settings, existingServer: nil)
            case .edit(let server):
                ServerFormView(settings: settings, existingServer: server)
            }
        }
        .alert(item: $serverToDelete) { server in
            Alert(
                title: Text("Delete Server"),
                message: Text("Are you sure you want to remove '\(server.name)'?"),
                primaryButton: .destructive(Text("Delete")) {
                    settings.removeServer(id: server.id)
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct DropViewDelegate: DropDelegate {
    let destinationItem: ProxmoxServerConfig
    @Binding var servers: [ProxmoxServerConfig]
    @Binding var draggedItem: ProxmoxServerConfig?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        self.draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else { return }
        
        if draggedItem != destinationItem {
            let from = servers.firstIndex(of: draggedItem)!
            let to = servers.firstIndex(of: destinationItem)!
            
            withAnimation {
                servers.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

enum SettingsSheet: Identifiable {
    case add
    case edit(ProxmoxServerConfig)
    
    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let server): return server.id.uuidString
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
