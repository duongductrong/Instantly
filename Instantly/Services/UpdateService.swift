import Foundation
import Sparkle

@MainActor
final class UpdateService {
    static let shared = UpdateService()

    let updaterController: SPUStandardUpdaterController

    private init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var updater: SPUUpdater {
        updaterController.updater
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
