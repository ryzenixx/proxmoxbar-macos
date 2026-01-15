import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsService
    @ObservedObject var launchService: LaunchAtLoginService
    @ObservedObject var updaterController: UpdaterController
    var onBack: () -> Void
    
    @State private var activeSheet: SettingsSheet?
    @State private var activeAlert: ActiveAlert?
    
    // For Drag and Drop
    @State private var draggedItem: ProxmoxServerConfig?
    
    enum ActiveAlert: Identifiable {
        case delete(ProxmoxServerConfig)
        case beta
        
        var id: String {
            switch self {
            case .delete(let server): return "delete-\(server.id)"
            case .beta: return "beta"
            }
        }
    }
    
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
                                            activeAlert = .delete(server)
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
                        
                        VStack(spacing: 12) {
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
                            
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Enable Notifications")
                                            .font(.system(size: 13))
                                        
                                        HStack(spacing: 2) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.system(size: 8))
                                            Text("BETA")
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(4)
                                    }
                                    
                                    #if DEBUG
                                    Text("Notifications disabled in development build")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    #endif
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: {
                                        #if DEBUG
                                        return false
                                        #else
                                        return settings.enableNotifications
                                        #endif
                                    },
                                    set: { newValue in
                                        #if !DEBUG
                                        if newValue {
                                            activeAlert = .beta
                                        } else {
                                            settings.enableNotifications = false
                                        }
                                        #endif
                                    }
                                ))
                                .labelsHidden()
                                .toggleStyle(.switch)
                                #if DEBUG
                                .disabled(true)
                                #endif
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
                
                HStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "https://github.com/ryzenixx/proxmoxbar-macos") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 10))
                            Text("View on GitHub")
                        }
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                    }
                    .buttonStyle(.plain)
                    .onHover { inside in
                        inside ? NSCursor.pointingHand.push() : NSCursor.pop()
                    }

                    Text("|")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.3))

                    Button {
                        if let url = URL(string: "https://ko-fi.com/ryzenixx") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 10))
                            Text("Buy me a coffee")
                        }
                        .font(.caption2)
                        .foregroundColor(Color(red: 1.0, green: 0.37, blue: 0.0))
                    }
                    .buttonStyle(.plain)
                    .onHover { inside in
                        inside ? NSCursor.pointingHand.push() : NSCursor.pop()
                    }
                }
                .padding(.top, 4)
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
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .delete(let server):
                return Alert(
                    title: Text("Delete Server"),
                    message: Text("Are you sure you want to remove '\(server.name)'?"),
                    primaryButton: .destructive(Text("Delete")) {
                        settings.removeServer(id: server.id)
                    },
                    secondaryButton: .cancel()
                )
            case .beta:
                return Alert(
                    title: Text("Enable Beta Notifications?"),
                    message: Text("This feature is currently in BETA. Enabling notifications involves background monitoring which may be unstable or inaccurate.\n\nUse at your own risk."),
                    primaryButton: .destructive(Text("Enable")) {
                        settings.enableNotifications = true
                        Task {
                            _ = await NotificationManager.shared.requestPermission()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
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
