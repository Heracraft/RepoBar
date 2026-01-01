// Sources/Platform/Linux/LinuxPlatformMenu.swift
// Linux implementation of menu using DBusMenu protocol

#if os(Linux)

import Foundation

/// Linux menu implementation using DBusMenu protocol
///
/// This is a placeholder that will eventually implement the DBusMenu specification
/// to provide menus that integrate with KDE and other Linux desktop environments.
///
/// ## Implementation Guide
///
/// The DBusMenu protocol provides a way to export menus over D-Bus so that they
/// can be displayed by desktop environments like KDE Plasma.
///
/// ### DBusMenu D-Bus Interface
///
/// **Interface**: com.canonical.dbusmenu
/// **Object Path**: Application-specific (e.g., "/MenuBar" or "/com/steipete/repobar/menus/0")
///
/// #### Methods
///
/// 1. **GetLayout(parentId, recursionDepth) -> (revision, layout)**
///    - Returns the menu structure starting from parentId
///    - Layout is a nested structure of menu items with properties
///    - revision is incremented when menu changes
///
/// 2. **GetGroupProperties(ids, propertyNames) -> properties**
///    - Get specific properties for multiple items at once
///    - Optimizes D-Bus traffic
///
/// 3. **GetProperty(id, name) -> value**
///    - Get a single property of a menu item
///
/// 4. **Event(id, eventId, data, timestamp)**
///    - Called when user interacts with menu item
///    - eventId: "clicked", "opened", "closed"
///
/// 5. **AboutToShow(id) -> needsUpdate**
///    - Called before menu is shown
///    - Return true if menu will be updated
///
/// #### Signals
///
/// 1. **LayoutUpdated(revision, parent)**
///    - Emitted when menu structure changes
///    - Clients should call GetLayout to refresh
///
/// 2. **ItemsPropertiesUpdated(updatedProps, removedProps)**
///    - Emitted when item properties change
///    - updatedProps: [(id, {property: value})]
///    - removedProps: [(id, [propertyNames])]
///
/// #### Properties
///
/// - **Version**: uint32, should be 3 or 4
/// - **TextDirection**: string, "ltr" or "rtl"
/// - **Status**: string, "normal" or "notice"
/// - **IconThemePath**: array of strings, additional icon search paths
///
/// ### Menu Item Properties
///
/// Each menu item is identified by an int32 ID and has these properties:
///
/// **Core Properties**:
/// - `type`: string - "standard", "separator", or omitted for standard
/// - `label`: string - Display text (may contain mnemonics with _)
/// - `enabled`: bool - Whether item is clickable (default: true)
/// - `visible`: bool - Whether item is shown (default: true)
/// - `icon-name`: string - Icon name from theme
/// - `icon-data`: byte array - Raw icon data (PNG format)
///
/// **Submenu Properties**:
/// - `children-display`: string - "submenu" if has children
///
/// **Toggle Properties**:
/// - `toggle-type`: string - "checkmark" or "radio"
/// - `toggle-state`: int32 - 0 (unchecked), 1 (checked), -1 (mixed)
///
/// **Shortcut Properties**:
/// - `shortcut`: array of arrays - [[modifiers, key, ...]]
///   - modifiers: "Control", "Alt", "Shift", "Super"
///   - key: keysym name (e.g., "a", "Return", "F1")
///
/// **Metadata**:
/// - `disposition`: string - "normal", "informative", "warning", "alert"
///
/// ### Implementation Steps
///
/// 1. **Export Menu Object**:
///    ```swift
///    func exportToDBus(connection: DBusConnection, path: String) {
///        let object = connection.registerObject(path: path)
///        object.exportInterface("com.canonical.dbusmenu",
///            methods: [
///                "GetLayout": getLayout,
///                "GetProperty": getProperty,
///                "Event": handleEvent,
///                "AboutToShow": aboutToShow
///            ],
///            properties: [
///                "Version": 3,
///                "TextDirection": "ltr",
///                "Status": "normal"
///            ]
///        )
///    }
///    ```
///
/// 2. **Build Menu Structure**:
///    - Root menu item has ID 0
///    - Assign unique IDs to each menu item (incrementing integers)
///    - Store mapping of ID -> MenuItem
///
/// 3. **Implement GetLayout**:
///    ```swift
///    func getLayout(parentId: Int32, recursionDepth: Int32) -> (UInt32, MenuLayout) {
///        let revision = currentRevision
///        let layout = buildLayout(fromParent: parentId, depth: recursionDepth)
///        return (revision, layout)
///    }
///    ```
///
/// 4. **Handle Events**:
///    ```swift
///    func handleEvent(id: Int32, eventId: String, data: Variant, timestamp: UInt32) {
///        if eventId == "clicked" {
///            if let item = itemsById[id] {
///                item.action?()
///            }
///        }
///    }
///    ```
///
/// 5. **Emit Signals on Changes**:
///    - When items added/removed: emit LayoutUpdated
///    - When properties change: emit ItemsPropertiesUpdated
///
/// ### Menu Layout Structure
///
/// The layout returned by GetLayout is a nested structure:
/// ```
/// (id, properties, children)
/// where children is an array of (id, properties, children)
/// ```
///
/// Example in Swift pseudo-code:
/// ```swift
/// struct MenuLayout {
///     let id: Int32
///     let properties: [String: Variant]
///     let children: [MenuLayout]
/// }
/// ```
///
/// ### Testing
///
/// 1. Export menu to D-Bus
/// 2. Inspect with D-Bus tools:
///    ```bash
///    # List methods
///    qdbus com.steipete.repobar /MenuBar
///
///    # Get layout
///    qdbus com.steipete.repobar /MenuBar com.canonical.dbusmenu.GetLayout 0 -1
///    ```
/// 3. Monitor events:
///    ```bash
///    dbus-monitor "interface='com.canonical.dbusmenu'"
///    ```
///
/// ### Dependencies
///
/// Same D-Bus library as LinuxSystemTray:
/// ```swift
/// .package(url: "https://github.com/PADL/swift-dbus", from: "1.0.0"),
/// ```
///
/// ### References
/// - [DBusMenu Protocol](https://github.com/AyatanaIndicators/libdbusmenu)
/// - [DBusMenu XML Spec](https://github.com/AyatanaIndicators/libdbusmenu/blob/master/libdbusmenu-glib/dbus-menu.xml)
/// - [Unity Indicators](https://wiki.ubuntu.com/DesktopExperienceTeam/ApplicationIndicators)
///
/// For detailed implementation examples, see:
/// - docs/FUTURE_WORK.md - Task 1.2: DBusMenu Protocol
/// - docs/platform-abstraction-examples.md
public final class LinuxPlatformMenu: PlatformMenu {
    private var items: [PlatformMenuItem] = []
    private var menuTitle: String = ""

    // TODO: Add D-Bus export properties
    // private var dbusConnection: DBusConnection?
    // private var objectPath: String?
    // private var itemsById: [Int32: LinuxPlatformMenuItem] = [:]
    // private var nextItemId: Int32 = 1 // Root is 0
    // private var revision: UInt32 = 1

    public init() {
        // TODO: Initialize DBusMenu structure
        // itemsById[0] = self // Root menu
    }

    public func addItem(_ item: PlatformMenuItem) {
        items.append(item)

        // TODO: Assign ID to new item
        // if let linuxItem = item as? LinuxPlatformMenuItem {
        //     linuxItem.itemId = nextItemId
        //     itemsById[nextItemId] = linuxItem
        //     nextItemId += 1
        // }

        // TODO: Emit LayoutUpdated signal if already exported
        // if let connection = dbusConnection, let path = objectPath {
        //     revision += 1
        //     connection.emitSignal("LayoutUpdated", revision, 0, on: path)
        // }
    }

    public func addSeparator() {
        // TODO: Create separator item
        // let separator = LinuxPlatformMenuItem(title: "")
        // separator.type = "separator"
        // separator.itemId = nextItemId
        // itemsById[nextItemId] = separator
        // items.append(separator)
        // nextItemId += 1

        // TODO: Emit LayoutUpdated signal
        // if let connection = dbusConnection, let path = objectPath {
        //     revision += 1
        //     connection.emitSignal("LayoutUpdated", revision, 0, on: path)
        // }
    }

    public func removeAllItems() {
        items.removeAll()

        // TODO: Clear items mapping but keep root
        // itemsById = [0: self]
        // nextItemId = 1

        // TODO: Emit LayoutUpdated signal
        // if let connection = dbusConnection, let path = objectPath {
        //     revision += 1
        //     connection.emitSignal("LayoutUpdated", revision, 0, on: path)
        // }
    }

    public var title: String {
        get { menuTitle }
        set {
            menuTitle = newValue
            // TODO: Update menu title if supported
            // Note: DBusMenu doesn't have explicit menu title,
            // but could be set as a property on the root item
        }
    }

    // TODO: Implement D-Bus export method
    // func exportToDBus(connection: DBusConnection, path: String) {
    //     dbusConnection = connection
    //     objectPath = path
    //
    //     let object = connection.registerObject(path: path)
    //     object.exportInterface("com.canonical.dbusmenu",
    //         methods: [
    //             ("GetLayout", getLayout),
    //             ("GetGroupProperties", getGroupProperties),
    //             ("GetProperty", getProperty),
    //             ("Event", handleEvent),
    //             ("AboutToShow", aboutToShow)
    //         ],
    //         properties: [
    //             "Version": Variant(3 as UInt32),
    //             "TextDirection": Variant("ltr"),
    //             "Status": Variant("normal")
    //         ],
    //         signals: ["LayoutUpdated", "ItemsPropertiesUpdated"]
    //     )
    // }

    // TODO: Implement GetLayout method
    // private func getLayout(parentId: Int32, recursionDepth: Int32) -> (UInt32, MenuLayout) {
    //     var layout: MenuLayout
    //     if parentId == 0 {
    //         // Build layout from root
    //         layout = buildLayoutForItems(items, depth: recursionDepth)
    //     } else if let item = itemsById[parentId] {
    //         // Build layout from specific item
    //         layout = buildLayoutForItem(item, depth: recursionDepth)
    //     } else {
    //         // Invalid parent ID
    //         layout = MenuLayout(id: parentId, properties: [:], children: [])
    //     }
    //     return (revision, layout)
    // }

    // TODO: Implement Event handler
    // private func handleEvent(id: Int32, eventId: String, data: Variant, timestamp: UInt32) {
    //     guard let item = itemsById[id] else { return }
    //
    //     switch eventId {
    //     case "clicked":
    //         item.action?()
    //     case "opened":
    //         // Submenu opened
    //         break
    //     case "closed":
    //         // Submenu closed
    //         break
    //     default:
    //         break
    //     }
    // }

    // TODO: Implement AboutToShow
    // private func aboutToShow(id: Int32) -> Bool {
    //     // Return true if menu will be updated
    //     // Could be used to lazy-load submenu content
    //     return false
    // }

    // TODO: Helper to build menu layout structure
    // private func buildLayoutForItems(_ items: [PlatformMenuItem], depth: Int32) -> MenuLayout {
    //     var children: [MenuLayout] = []
    //
    //     if depth != 0 {
    //         for item in items {
    //             if let linuxItem = item as? LinuxPlatformMenuItem {
    //                 let props = linuxItem.getDBusProperties()
    //                 var itemChildren: [MenuLayout] = []
    //
    //                 // Recursively build submenu if present and depth allows
    //                 if let submenu = linuxItem.submenu as? LinuxPlatformMenu,
    //                    depth != 1 {
    //                     itemChildren = submenu.buildLayoutForItems(submenu.items, depth: depth - 1).children
    //                 }
    //
    //                 let itemLayout = MenuLayout(
    //                     id: linuxItem.itemId,
    //                     properties: props,
    //                     children: itemChildren
    //                 )
    //                 children.append(itemLayout)
    //             }
    //         }
    //     }
    //
    //     return MenuLayout(id: 0, properties: [:], children: children)
    // }
}

/// Linux menu item implementation
public final class LinuxPlatformMenuItem: PlatformMenuItem {
    private var itemTitle: String
    private var enabled: Bool
    private var itemSubmenu: PlatformMenu?
    private var itemAction: (() -> Void)?
    private var itemKeyEquivalent: String
    private var itemState: MenuItemState

    // TODO: Add D-Bus menu item properties
    // var itemId: Int32 = 0
    // var itemType: String = "standard" // "standard", "separator"
    // var iconName: String? = nil
    // var disposition: String = "normal" // "normal", "informative", "warning", "alert"

    public init(title: String = "") {
        self.itemTitle = title
        self.enabled = true
        self.itemSubmenu = nil
        self.itemAction = nil
        self.itemKeyEquivalent = ""
        self.itemState = .off
    }

    public var title: String {
        get { itemTitle }
        set {
            itemTitle = newValue
            // TODO: Update DBusMenu item label property
            // Emit ItemsPropertiesUpdated signal with:
            // [(itemId, ["label": newValue])]
        }
    }

    public var isEnabled: Bool {
        get { enabled }
        set {
            enabled = newValue
            // TODO: Update DBusMenu item enabled property
            // Emit ItemsPropertiesUpdated signal with:
            // [(itemId, ["enabled": newValue])]
        }
    }

    public var submenu: PlatformMenu? {
        get { itemSubmenu }
        set {
            itemSubmenu = newValue
            // TODO: Set DBusMenu item children-display property to "submenu"
            // Export the submenu's items as children in GetLayout response
            // Emit LayoutUpdated if menu structure changes
        }
    }

    public var action: (() -> Void)? {
        get { itemAction }
        set { itemAction = newValue }
    }

    public var keyEquivalent: String {
        get { itemKeyEquivalent }
        set {
            itemKeyEquivalent = newValue
            // TODO: Convert to DBusMenu shortcut format
            // Parse string like "⌘N" to [["Super"], "n"]
            // or "^⌥S" to [["Control", "Alt"], "s"]
            // Set shortcut property: [[modifiers, key]]
            // Emit ItemsPropertiesUpdated signal
        }
    }

    public var state: MenuItemState {
        get { itemState }
        set {
            itemState = newValue
            // TODO: Update DBusMenu toggle properties
            // Set toggle-type: "checkmark" or "radio"
            // Set toggle-state: 0 (off), 1 (on), -1 (mixed)
            // Emit ItemsPropertiesUpdated signal with:
            // [(itemId, ["toggle-type": type, "toggle-state": state])]
        }
    }

    // TODO: Add helper to get all D-Bus properties for this item
    // func getDBusProperties() -> [String: Variant] {
    //     var props: [String: Variant] = [
    //         "label": Variant(itemTitle),
    //         "enabled": Variant(enabled),
    //         "visible": Variant(true)
    //     ]
    //
    //     // Add type if separator
    //     if itemType == "separator" {
    //         props["type"] = Variant("separator")
    //     }
    //
    //     // Add submenu indicator
    //     if itemSubmenu != nil {
    //         props["children-display"] = Variant("submenu")
    //     }
    //
    //     // Add toggle properties
    //     if itemState != .off {
    //         props["toggle-type"] = Variant("checkmark")
    //         let toggleState: Int32 = itemState == .on ? 1 : (itemState == .mixed ? -1 : 0)
    //         props["toggle-state"] = Variant(toggleState)
    //     }
    //
    //     // Add icon if present
    //     if let icon = iconName {
    //         props["icon-name"] = Variant(icon)
    //     }
    //
    //     // Add shortcut if present
    //     if !itemKeyEquivalent.isEmpty {
    //         let shortcut = convertKeyEquivalentToDBusShortcut(itemKeyEquivalent)
    //         props["shortcut"] = Variant(shortcut)
    //     }
    //
    //     return props
    // }
    //
    // // Convert macOS-style key equivalent to DBusMenu shortcut format
    // private func convertKeyEquivalentToDBusShortcut(_ keyEq: String) -> [[String]] {
    //     var modifiers: [String] = []
    //     var key = ""
    //
    //     // Parse modifiers: ⌘ = Super, ⌃ = Control, ⌥ = Alt, ⇧ = Shift
    //     for char in keyEq {
    //         switch char {
    //         case "⌘", "": modifiers.append("Super")
    //         case "⌃": modifiers.append("Control")
    //         case "⌥": modifiers.append("Alt")
    //         case "⇧": modifiers.append("Shift")
    //         default: key = String(char)
    //         }
    //     }
    //
    //     return [modifiers + [key]]
    // }
}

#endif
