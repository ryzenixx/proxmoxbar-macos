import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        ObservingView(onWindow: onWindow)
    }

    func updateNSView(_ view: NSView, context: Context) {
        (view as? ObservingView)?.reportIfPossible()
    }

    private final class ObservingView: NSView {
        private let onWindow: (NSWindow) -> Void
        private var hasReported = false

        init(onWindow: @escaping (NSWindow) -> Void) {
            self.onWindow = onWindow
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("WindowAccessor is not loaded from a nib.")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            reportIfPossible()
        }

        func reportIfPossible() {
            guard hasReported == false, let window else { return }
            hasReported = true
            onWindow(window)
        }
    }
}
