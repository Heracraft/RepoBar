// Sources/Platform/macOS/MacOSSystemTray.swift
// macOS implementation of system tray using NSStatusBar

#if os(macOS)

import AppKit
import Foundation

/// macOS system tray implementation using NSStatusBar and NSStatusItem
///
/// Wraps AppKit's NSStatusBar to provide a cross-platform interface.
public final class MacOSSystemTray: SystemTray {
    private let statusItem: NSStatusItem
    private var currentMenu: NSMenu?

    public init() {
        // Create a status item in the system menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }

    public func setIcon(_ image: PlatformImage) {
        statusItem.button?.image = image
    }

    public func setMenu(_ menu: PlatformMenu) {
        guard let nsMenu = menu as? MacOSPlatformMenu else {
            fatalError("MacOSSystemTray requires MacOSPlatformMenu")
        }
        statusItem.menu = nsMenu.nsMenu
        currentMenu = nsMenu.nsMenu
    }

    public func show() {
        statusItem.isVisible = true
    }

    public func hide() {
        statusItem.isVisible = false
    }

    public var isVisible: Bool {
        statusItem.isVisible
    }

    /// Access to the underlying NSStatusItem for macOS-specific features
    public var underlyingStatusItem: NSStatusItem {
        statusItem
    }
}

#endif
