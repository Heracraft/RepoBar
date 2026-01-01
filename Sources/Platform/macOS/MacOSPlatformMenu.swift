// Sources/Platform/macOS/MacOSPlatformMenu.swift
// macOS implementation of menu using NSMenu

#if os(macOS)

import AppKit
import Foundation

/// macOS menu implementation using NSMenu
///
/// Wraps AppKit's NSMenu to provide a cross-platform interface.
public final class MacOSPlatformMenu: PlatformMenu {
    internal let nsMenu: NSMenu

    public init(title: String = "") {
        nsMenu = NSMenu(title: title)
    }

    /// Initialize with an existing NSMenu (for wrapping existing menus)
    public init(wrapping menu: NSMenu) {
        nsMenu = menu
    }

    public func addItem(_ item: PlatformMenuItem) {
        guard let macItem = item as? MacOSPlatformMenuItem else {
            fatalError("MacOSPlatformMenu requires MacOSPlatformMenuItem")
        }
        nsMenu.addItem(macItem.nsMenuItem)
    }

    public func addSeparator() {
        nsMenu.addItem(NSMenuItem.separator())
    }

    public func removeAllItems() {
        nsMenu.removeAllItems()
    }

    public var title: String {
        get { nsMenu.title }
        set { nsMenu.title = newValue }
    }
}

/// macOS menu item implementation using NSMenuItem
public final class MacOSPlatformMenuItem: PlatformMenuItem {
    internal let nsMenuItem: NSMenuItem
    private var actionClosure: (() -> Void)?

    public init(title: String = "", action: (() -> Void)? = nil) {
        nsMenuItem = NSMenuItem(
            title: title,
            action: action != nil ? #selector(handleAction) : nil,
            keyEquivalent: ""
        )
        actionClosure = action
        if action != nil {
            nsMenuItem.target = self
        }
    }

    /// Initialize with an existing NSMenuItem (for wrapping existing menu items)
    public init(wrapping menuItem: NSMenuItem) {
        nsMenuItem = menuItem
    }

    @objc private func handleAction() {
        actionClosure?()
    }

    public var title: String {
        get { nsMenuItem.title }
        set { nsMenuItem.title = newValue }
    }

    public var isEnabled: Bool {
        get { nsMenuItem.isEnabled }
        set { nsMenuItem.isEnabled = newValue }
    }

    public var submenu: PlatformMenu? {
        get {
            if let nsSubmenu = nsMenuItem.submenu {
                return MacOSPlatformMenu(wrapping: nsSubmenu)
            }
            return nil
        }
        set {
            if let macMenu = newValue as? MacOSPlatformMenu {
                nsMenuItem.submenu = macMenu.nsMenu
            } else {
                nsMenuItem.submenu = nil
            }
        }
    }

    public var action: (() -> Void)? {
        get { actionClosure }
        set {
            actionClosure = newValue
            if newValue != nil {
                nsMenuItem.action = #selector(handleAction)
                nsMenuItem.target = self
            } else {
                nsMenuItem.action = nil
                nsMenuItem.target = nil
            }
        }
    }

    public var keyEquivalent: String {
        get { nsMenuItem.keyEquivalent }
        set { nsMenuItem.keyEquivalent = newValue }
    }

    public var state: MenuItemState {
        get {
            switch nsMenuItem.state {
            case .on: return .on
            case .off: return .off
            case .mixed: return .mixed
            @unknown default: return .off
            }
        }
        set {
            switch newValue {
            case .on: nsMenuItem.state = .on
            case .off: nsMenuItem.state = .off
            case .mixed: nsMenuItem.state = .mixed
            }
        }
    }
}

#endif
