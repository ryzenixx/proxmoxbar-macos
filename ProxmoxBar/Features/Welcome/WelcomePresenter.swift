import AppKit
import SwiftUI

@MainActor
final class WelcomePresenter {
    private let state: WelcomeState
    private var window: NSWindow?

    init(state: WelcomeState = WelcomeState()) {
        self.state = state
    }

    func presentIfNeeded() {
        guard state.hasBeenSeen == false else { return }
        present()
    }

    func present() {
        if let window {
            bringToFront(window)
            return
        }
        let window = makeWindow()
        self.window = window
        bringToFront(window)
    }

    private func makeWindow() -> NSWindow {
        let content = WelcomeWindow(onDismiss: dismiss)
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to ProxmoxBar"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: content)
        window.setContentSize(window.contentView?.fittingSize ?? .zero)
        window.center()
        return window
    }

    private func bringToFront(_ window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        if let frontmost = NSWorkspace.shared.frontmostApplication {
            NSRunningApplication.current.activate(from: frontmost, options: [.activateAllWindows])
        }
        window.makeKeyAndOrderFront(nil)
    }

    private func dismiss() {
        state.markSeen()
        window?.close()
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
