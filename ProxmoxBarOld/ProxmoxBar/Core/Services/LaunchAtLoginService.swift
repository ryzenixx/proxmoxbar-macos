import Foundation
import ServiceManagement
import SwiftUI

@MainActor
class LaunchAtLoginService: ObservableObject {
    @Published var isEnabled: Bool = false
    
    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
                isEnabled = false
            } else {
                try SMAppService.mainApp.register()
                isEnabled = true
            }
        } catch {
            print("Failed to toggle Launch at Login: \(error)")
        }
    }
}
