import SwiftUI
import AppKit

extension Color {
    static var adaptiveGreen: Color {
        Color(
            nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    return .green
                }
                return NSColor(displayP3Red: 0, green: 0.6, blue: 0, alpha: 1)
            })
        )
    }

    static var adaptiveRed: Color {
        Color(
            nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    return .red
                }
                return NSColor(displayP3Red: 0.8, green: 0, blue: 0, alpha: 1)
            })
        )
    }

    static var adaptiveOrange: Color {
        Color(
            nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    return .orange
                }
                return NSColor(displayP3Red: 0.8, green: 0.4, blue: 0, alpha: 1)
            })
        )
    }
}
