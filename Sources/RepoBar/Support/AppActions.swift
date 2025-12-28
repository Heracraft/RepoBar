import AppKit

@MainActor
enum AppActions {
    static func openSettings() {
        SettingsWindowController.shared.show()
    }

    static func openAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
