// Sources/Platform/Protocol/PlatformMenu.swift
// Platform abstraction for menu system

import Foundation

/// Protocol for cross-platform menu functionality
///
/// On macOS, this wraps NSMenu.
/// On Linux, this implements DBusMenu protocol.
public protocol PlatformMenu: AnyObject {
    /// Adds a menu item to the menu
    func addItem(_ item: PlatformMenuItem)

    /// Adds a separator line to the menu
    func addSeparator()

    /// Removes all items from the menu
    func removeAllItems()

    /// The title of the menu
    var title: String { get set }
}

/// Protocol for cross-platform menu item functionality
///
/// On macOS, this wraps NSMenuItem.
/// On Linux, this implements DBusMenu item protocol.
public protocol PlatformMenuItem: AnyObject {
    /// The display title of the menu item
    var title: String { get set }

    /// Whether the menu item is enabled and clickable
    var isEnabled: Bool { get set }

    /// Optional submenu for hierarchical menus
    var submenu: PlatformMenu? { get set }

    /// Action to perform when the menu item is clicked
    var action: (() -> Void)? { get set }

    /// Key equivalent (keyboard shortcut) for the menu item
    var keyEquivalent: String { get set }

    /// The state of the menu item (for checkboxes, etc.)
    var state: MenuItemState { get set }
}

/// Menu item state for checkboxes and radio buttons
public enum MenuItemState {
    case off
    case on
    case mixed
}
