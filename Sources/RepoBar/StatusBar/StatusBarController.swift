import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    let menuManager: StatusBarMenuManager
    private let iconController: StatusBarIconController
    private let appState: AppState
    private var updateTimer: Timer?

    init(appState: AppState) {
        self.appState = appState
        self.menuManager = StatusBarMenuManager(appState: appState)
        self.iconController = StatusBarIconController()
        super.init()
        self.setupStatusItem()
        self.startTimer()
    }

    private func setupStatusItem() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.imagePosition = .imageLeading
        button.toolTip = "RepoBar"
        self.iconController.update(button: button, session: self.appState.session)
        if let statusItem {
            self.menuManager.attachMainMenu(to: statusItem)
        }
    }

    private func startTimer() {
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.iconController.update(button: self.statusItem?.button, session: self.appState.session)
            }
        }
        self.updateTimer?.fire()
    }

}
