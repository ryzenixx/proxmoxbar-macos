import Foundation
import Sparkle
import SwiftUI

class UpdaterController: NSObject, ObservableObject, SPUUpdaterDelegate {
    private var updaterController: SPUStandardUpdaterController?
    
    @Published var canCheckForUpdates = false
    
    override init() {
        super.init()
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        
        // Sparkle needs a bundled app context with update metadata in Info.plist.
        guard bundleIdentifier != nil,
              !(feedURL?.isEmpty ?? true),
              !(publicKey?.isEmpty ?? true) else {
            canCheckForUpdates = false
            print("⚠️ Sparkle metadata not available in this build. Updates disabled.")
            return
        }
        
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        canCheckForUpdates = true
    }
    
    @MainActor
    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        updaterController?.checkForUpdates(nil)
    }
    
    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        // Appcast loaded
    }
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        // Update found
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        // No update found
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        // Error handling
    }
}
