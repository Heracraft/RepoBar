import Sparkle

/// Simple Sparkle wrapper so we can call from menus without passing around the updater.
@MainActor
final class SparkleController {
    static let shared = SparkleController()
    private let updaterController: SPUStandardUpdaterController

    private init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        self.updaterController.checkForUpdates(nil)
    }
}
