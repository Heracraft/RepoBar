// Sources/Platform/Protocol/SystemTray.swift
// Platform abstraction for system tray/status bar integration

import Foundation

/// Protocol for system tray integration across platforms
///
/// On macOS, this wraps NSStatusBar and NSStatusItem.
/// On Linux, this implements StatusNotifierItem via D-Bus.
public protocol SystemTray: AnyObject {
    /// Sets the icon displayed in the system tray
    func setIcon(_ image: PlatformImage)

    /// Sets the menu that appears when clicking the tray icon
    func setMenu(_ menu: PlatformMenu)

    /// Shows the tray icon
    func show()

    /// Hides the tray icon
    func hide()

    /// Indicates whether the tray icon is currently visible
    var isVisible: Bool { get }
}
