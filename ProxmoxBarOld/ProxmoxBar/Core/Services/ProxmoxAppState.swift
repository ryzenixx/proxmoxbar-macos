import SwiftUI

@MainActor
class ProxmoxAppState: ObservableObject {
    let settings = SettingsService()
    
    lazy var viewModel = ProxmoxViewModel(settings: settings)
}
