import SwiftUI
import AppKit

struct CursorFixView: NSViewRepresentable {
    func makeNSView(context: Context) -> CursorFixNSView {
        return CursorFixNSView()
    }
    
    func updateNSView(_ nsView: CursorFixNSView, context: Context) {}
}

class CursorFixNSView: NSView {
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }
}
