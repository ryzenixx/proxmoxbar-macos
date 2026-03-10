import SwiftUI

struct ServerFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: SettingsService
    
    var existingServer: ProxmoxServerConfig?
    
    @State private var name: String = ""
    @State private var url: String = "https://"
    @State private var tokenId: String = ""
    @State private var secret: String = ""
    
    init(settings: SettingsService, existingServer: ProxmoxServerConfig? = nil) {
        self.settings = settings
        self.existingServer = existingServer
        
        if let server = existingServer {
            _name = State(initialValue: server.name)
            _url = State(initialValue: server.url)
            _tokenId = State(initialValue: server.tokenId)
            _secret = State(initialValue: server.secret)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(existingServer == nil ? "Add Proxmox Node" : "Edit Proxmox Node")
                .font(.headline)
            
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Important Configuration")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Please follow the **Permission & Security** guide in the [README](https://github.com/ryzenixx/proxmoxbar-macos?tab=readme-ov-file#-permissions--security) to configure your API Token correctly.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("My Server", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Server URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("https://192.168.1.10:8006", text: $url)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            Divider()
            

            
            VStack(alignment: .leading, spacing: 4) {
                Text("Token ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("user@pam!tokenid", text: $tokenId)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Secret")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                SecureField("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", text: $secret)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(existingServer == nil ? "Add Server" : "Save Changes") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || url.isEmpty || tokenId.isEmpty || secret.isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active))
        .presentationBackground(.clear)
    }
    
    private func save() {
        if var server = existingServer {
            // Update
            server.name = name
            server.url = url
            server.tokenId = tokenId
            server.secret = secret
            settings.updateServer(server)
        } else {
            // Create
            let newServer = ProxmoxServerConfig(
                name: name,
                url: url,
                tokenId: tokenId,
                secret: secret
            )
            settings.addServer(newServer)
        }
        dismiss()
    }
}
