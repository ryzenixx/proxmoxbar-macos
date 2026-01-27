import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var appState: ProxmoxAppState!
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize NotificationManager to ensure delegate is set
        #if !DEBUG
        _ = NotificationManager.shared
        #endif
        
        appState = ProxmoxAppState()
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 500)
        popover.behavior = .applicationDefined
        
        let launchService = LaunchAtLoginService()
        let updaterController = UpdaterController()
        
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(
                viewModel: appState.viewModel,
                settings: appState.settings,
                launchService: launchService,
                updaterController: updaterController
            )
                .frame(width: 420, height: 500)
        )
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = getMenuBarIcon()
            button.action = #selector(buttonPressed(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopover(sender: nil)
            }
        }
    }
    
    @MainActor
    @objc func buttonPressed(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Proxmox Bar", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            if popover.isShown {
                closePopover(sender: sender)
            } else {
                if let button = statusItem.button {
                    Task { await appState.viewModel.loadData() }
                    
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    eventMonitor?.start()
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    @MainActor
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func getMenuBarIcon() -> NSImage {
        #if DEBUG
        if let moduleUrl = Bundle.module.url(forResource: "Assets/MenuBarIcon", withExtension: "png"),
           let image = NSImage(contentsOf: moduleUrl) {
            image.isTemplate = true
            image.size = CGSize(width: 15, height: 15)
            return image
        }
        #endif
        
        if let resourcePath = Bundle.main.resourcePath {
            let iconPath = resourcePath + "/MenuBarIcon.png"
            if let image = NSImage(contentsOfFile: iconPath) {
                image.isTemplate = true
                image.size = CGSize(width: 15, height: 15)
                return image
            }
        }
        
        return NSImage(systemSymbolName: "server.rack", accessibilityDescription: nil) ?? NSImage()
    }
    
    @MainActor
    func closePopover(sender: Any?) {
        if appState.settings.activeSheet != nil {
            return
        }
        
        popover.performClose(sender)
        eventMonitor?.stop()
    }
}
