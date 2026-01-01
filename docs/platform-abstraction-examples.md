---
summary: "Platform abstraction examples for RepoBar: practical code patterns for cross-platform support."
read_when:
  - Implementing Linux port
  - Creating platform-specific code
  - Understanding abstraction patterns
---

# Platform Abstraction Code Examples

This document provides concrete code examples for implementing platform abstractions in RepoBar.

## Basic Platform Detection

```swift
// Sources/Platform/PlatformInfo.swift
#if os(macOS)
public let currentPlatform = Platform.macOS
#elseif os(Linux)
public let currentPlatform = Platform.linux
#else
#error("Unsupported platform")
#endif

public enum Platform {
    case macOS
    case linux
}
```

## System Tray Abstraction

```swift
// Sources/Platform/Protocol/SystemTray.swift
import Foundation

/// Cross-platform system tray interface
public protocol SystemTray: AnyObject {
    /// Set the icon displayed in the system tray
    func setIcon(_ image: PlatformImage)
    
    /// Set the tooltip text
    func setToolTip(_ text: String)
    
    /// Set the menu that appears when clicking the tray icon
    func setMenu(_ menu: PlatformMenu)
    
    /// Show the system tray icon
    func show()
    
    /// Hide the system tray icon
    func hide()
    
    /// Whether the tray icon is currently visible
    var isVisible: Bool { get }
}
```

### macOS Implementation

```swift
// Sources/Platform/macOS/MacOSSystemTray.swift
#if os(macOS)
import AppKit

public final class MacOSSystemTray: SystemTray {
    private let statusItem: NSStatusItem
    
    public init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }
    
    public func setIcon(_ image: PlatformImage) {
        self.statusItem.button?.image = image
    }
    
    public func setToolTip(_ text: String) {
        self.statusItem.button?.toolTip = text
    }
    
    public func setMenu(_ menu: PlatformMenu) {
        guard let nsMenu = menu as? MacOSMenu else { return }
        self.statusItem.menu = nsMenu.nsMenu
    }
    
    public func show() {
        self.statusItem.isVisible = true
    }
    
    public func hide() {
        self.statusItem.isVisible = false
    }
    
    public var isVisible: Bool {
        get { self.statusItem.isVisible }
        set { self.statusItem.isVisible = newValue }
    }
}
#endif
```

### Linux Implementation (Stub)

```swift
// Sources/Platform/Linux/LinuxSystemTray.swift
#if os(Linux)
import Foundation

public final class LinuxSystemTray: SystemTray {
    private var _isVisible = false
    private var iconData: Data?
    private var toolTip: String?
    private var menu: PlatformMenu?
    
    public init() {
        // TODO: Initialize D-Bus connection
        // TODO: Register StatusNotifierItem
    }
    
    public func setIcon(_ image: PlatformImage) {
        // TODO: Convert image to PNG data
        // TODO: Send to D-Bus StatusNotifierItem
        self.iconData = image.pngData
    }
    
    public func setToolTip(_ text: String) {
        self.toolTip = text
        // TODO: Update D-Bus property
    }
    
    public func setMenu(_ menu: PlatformMenu) {
        self.menu = menu
        // TODO: Export DBusMenu
    }
    
    public func show() {
        self._isVisible = true
        // TODO: Update D-Bus visibility
    }
    
    public func hide() {
        self._isVisible = false
        // TODO: Update D-Bus visibility
    }
    
    public var isVisible: Bool {
        get { self._isVisible }
        set { newValue ? show() : hide() }
    }
}
#endif
```

## Menu Abstraction

```swift
// Sources/Platform/Protocol/PlatformMenu.swift
import Foundation

/// Cross-platform menu interface
public protocol PlatformMenu: AnyObject {
    /// Add an item to the menu
    func addItem(_ item: PlatformMenuItem)
    
    /// Add a separator
    func addSeparator()
    
    /// Remove all items
    func removeAllItems()
    
    /// All items in the menu
    var items: [PlatformMenuItem] { get }
    
    /// Update the menu (refresh display)
    func update()
}

/// Cross-platform menu item interface
public protocol PlatformMenuItem: AnyObject {
    /// The title text
    var title: String { get set }
    
    /// Whether the item is enabled
    var isEnabled: Bool { get set }
    
    /// Submenu attached to this item
    var submenu: PlatformMenu? { get set }
    
    /// Action to perform when clicked
    var action: (() -> Void)? { get set }
    
    /// Key equivalent (keyboard shortcut)
    var keyEquivalent: String { get set }
}
```

### macOS Menu Implementation

```swift
// Sources/Platform/macOS/MacOSMenu.swift
#if os(macOS)
import AppKit

public final class MacOSMenu: PlatformMenu {
    let nsMenu: NSMenu
    private var menuItems: [MacOSMenuItem] = []
    
    public init(title: String = "") {
        self.nsMenu = NSMenu(title: title)
    }
    
    public func addItem(_ item: PlatformMenuItem) {
        guard let macItem = item as? MacOSMenuItem else { return }
        self.nsMenu.addItem(macItem.nsMenuItem)
        self.menuItems.append(macItem)
    }
    
    public func addSeparator() {
        self.nsMenu.addItem(.separator())
    }
    
    public func removeAllItems() {
        self.nsMenu.removeAllItems()
        self.menuItems.removeAll()
    }
    
    public var items: [PlatformMenuItem] {
        return self.menuItems
    }
    
    public func update() {
        self.nsMenu.update()
    }
}

public final class MacOSMenuItem: PlatformMenuItem {
    let nsMenuItem: NSMenuItem
    private var actionHandler: (() -> Void)?
    
    public init(title: String) {
        self.nsMenuItem = NSMenuItem(
            title: title,
            action: #selector(Self.handleAction),
            keyEquivalent: ""
        )
        self.nsMenuItem.target = self
    }
    
    public var title: String {
        get { self.nsMenuItem.title }
        set { self.nsMenuItem.title = newValue }
    }
    
    public var isEnabled: Bool {
        get { self.nsMenuItem.isEnabled }
        set { self.nsMenuItem.isEnabled = newValue }
    }
    
    public var submenu: PlatformMenu? {
        get {
            // Return wrapped NSMenu if it exists
            return nil // Simplified
        }
        set {
            guard let macMenu = newValue as? MacOSMenu else { return }
            self.nsMenuItem.submenu = macMenu.nsMenu
        }
    }
    
    public var action: (() -> Void)? {
        get { self.actionHandler }
        set { self.actionHandler = newValue }
    }
    
    public var keyEquivalent: String {
        get { self.nsMenuItem.keyEquivalent }
        set { self.nsMenuItem.keyEquivalent = newValue }
    }
    
    @objc private func handleAction() {
        self.actionHandler?()
    }
}
#endif
```

### Linux Menu Implementation (Stub)

```swift
// Sources/Platform/Linux/LinuxMenu.swift
#if os(Linux)
import Foundation

public final class LinuxMenu: PlatformMenu {
    private var _items: [LinuxMenuItem] = []
    public let menuId: String
    
    public init(title: String = "") {
        self.menuId = UUID().uuidString
        // TODO: Register with DBusMenu
    }
    
    public func addItem(_ item: PlatformMenuItem) {
        guard let linuxItem = item as? LinuxMenuItem else { return }
        self._items.append(linuxItem)
        // TODO: Send DBusMenu ItemsPropertiesUpdated signal
    }
    
    public func addSeparator() {
        let separator = LinuxMenuItem(title: "", isSeparator: true)
        self._items.append(separator)
        // TODO: Send DBusMenu update
    }
    
    public func removeAllItems() {
        self._items.removeAll()
        // TODO: Send DBusMenu update
    }
    
    public var items: [PlatformMenuItem] {
        return self._items
    }
    
    public func update() {
        // TODO: Send DBusMenu LayoutUpdated signal
    }
}

public final class LinuxMenuItem: PlatformMenuItem {
    public let itemId: Int32
    private var _title: String
    private var _isEnabled: Bool
    private var _submenu: PlatformMenu?
    private var _action: (() -> Void)?
    private var _keyEquivalent: String
    public let isSeparator: Bool
    
    public init(title: String, isSeparator: Bool = false) {
        self.itemId = Int32.random(in: 1...Int32.max)
        self._title = title
        self._isEnabled = true
        self._keyEquivalent = ""
        self.isSeparator = isSeparator
    }
    
    public var title: String {
        get { self._title }
        set {
            self._title = newValue
            // TODO: Send DBusMenu property update
        }
    }
    
    public var isEnabled: Bool {
        get { self._isEnabled }
        set {
            self._isEnabled = newValue
            // TODO: Send DBusMenu property update
        }
    }
    
    public var submenu: PlatformMenu? {
        get { self._submenu }
        set {
            self._submenu = newValue
            // TODO: Send DBusMenu property update
        }
    }
    
    public var action: (() -> Void)? {
        get { self._action }
        set { self._action = newValue }
    }
    
    public var keyEquivalent: String {
        get { self._keyEquivalent }
        set { self._keyEquivalent = newValue }
    }
    
    public func executeAction() {
        self._action?()
    }
}
#endif
```

## Platform Image Types

```swift
// Sources/Platform/Protocol/PlatformTypes.swift
import Foundation

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
#elseif os(Linux)
public typealias PlatformImage = LinuxImage
public typealias PlatformColor = LinuxColor
#endif

#if os(Linux)
/// Minimal image representation for Linux
public struct LinuxImage {
    public let width: Int
    public let height: Int
    public let pngData: Data
    
    public init(width: Int, height: Int, pngData: Data) {
        self.width = width
        self.height = height
        self.pngData = pngData
    }
    
    /// Create from PNG file
    public init?(contentsOfFile path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        // Simplified - would need proper PNG parsing
        self.width = 64
        self.height = 64
        self.pngData = data
    }
}

/// Minimal color representation for Linux
public struct LinuxColor {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public static let red = LinuxColor(red: 1.0, green: 0.0, blue: 0.0)
    public static let green = LinuxColor(red: 0.0, green: 1.0, blue: 0.0)
    public static let blue = LinuxColor(red: 0.0, green: 0.0, blue: 1.0)
    public static let black = LinuxColor(red: 0.0, green: 0.0, blue: 0.0)
    public static let white = LinuxColor(red: 1.0, green: 1.0, blue: 1.0)
}
#endif
```

## Platform Factory

```swift
// Sources/Platform/PlatformFactory.swift
import Foundation

/// Factory for creating platform-specific instances
public final class PlatformFactory {
    /// Create a system tray for the current platform
    public static func createSystemTray() -> SystemTray {
        #if os(macOS)
        return MacOSSystemTray()
        #elseif os(Linux)
        return LinuxSystemTray()
        #endif
    }
    
    /// Create a menu for the current platform
    public static func createMenu(title: String = "") -> PlatformMenu {
        #if os(macOS)
        return MacOSMenu(title: title)
        #elseif os(Linux)
        return LinuxMenu(title: title)
        #endif
    }
    
    /// Create a menu item for the current platform
    public static func createMenuItem(title: String) -> PlatformMenuItem {
        #if os(macOS)
        return MacOSMenuItem(title: title)
        #elseif os(Linux)
        return LinuxMenuItem(title: title)
        #endif
    }
}
```

## Usage in Application Code

```swift
// Example: Creating system tray with menu
import Platform

class AppController {
    let systemTray: SystemTray
    let mainMenu: PlatformMenu
    
    init() {
        // Create platform-specific instances
        self.systemTray = PlatformFactory.createSystemTray()
        self.mainMenu = PlatformFactory.createMenu(title: "RepoBar")
        
        // Setup menu
        self.setupMenu()
        
        // Attach to system tray
        self.systemTray.setMenu(self.mainMenu)
        self.systemTray.setToolTip("RepoBar - GitHub at a glance")
        
        // Load icon
        #if os(macOS)
        if let icon = NSImage(named: "MenuBarIcon") {
            self.systemTray.setIcon(icon)
        }
        #elseif os(Linux)
        if let icon = LinuxImage(contentsOfFile: "/usr/share/icons/repobar/icon.png") {
            self.systemTray.setIcon(icon)
        }
        #endif
        
        self.systemTray.show()
    }
    
    private func setupMenu() {
        // Add menu items
        let refreshItem = PlatformFactory.createMenuItem(title: "Refresh Now")
        refreshItem.action = { [weak self] in
            self?.handleRefresh()
        }
        self.mainMenu.addItem(refreshItem)
        
        self.mainMenu.addSeparator()
        
        let settingsItem = PlatformFactory.createMenuItem(title: "Settings...")
        settingsItem.keyEquivalent = ","
        settingsItem.action = { [weak self] in
            self?.handleSettings()
        }
        self.mainMenu.addItem(settingsItem)
        
        self.mainMenu.addSeparator()
        
        let quitItem = PlatformFactory.createMenuItem(title: "Quit RepoBar")
        quitItem.keyEquivalent = "q"
        quitItem.action = { [weak self] in
            self?.handleQuit()
        }
        self.mainMenu.addItem(quitItem)
    }
    
    private func handleRefresh() {
        print("Refreshing...")
    }
    
    private func handleSettings() {
        print("Opening settings...")
    }
    
    private func handleQuit() {
        print("Quitting...")
        #if os(macOS)
        NSApplication.shared.terminate(nil)
        #elseif os(Linux)
        exit(0)
        #endif
    }
}
```

## Secure Storage Abstraction

```swift
// Sources/Platform/Protocol/SecureStorage.swift
import Foundation

public protocol SecureStorage {
    func store(_ data: Data, forKey key: String) throws
    func retrieve(forKey key: String) throws -> Data?
    func delete(forKey key: String) throws
}

// macOS implementation using Keychain
#if os(macOS)
import Security

public final class MacOSSecureStorage: SecureStorage {
    public func store(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "SecureStorage", code: Int(status))
        }
    }
    
    public func retrieve(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw NSError(domain: "SecureStorage", code: Int(status))
        }
        
        return result as? Data
    }
    
    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: "SecureStorage", code: Int(status))
        }
    }
}
#endif

// Linux implementation using libsecret (stub)
#if os(Linux)
public final class LinuxSecureStorage: SecureStorage {
    // TODO: Implement using libsecret or KWallet
    // For now, use encrypted file storage
    
    private let storageDirectory: URL
    
    public init() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.storageDirectory = home.appendingPathComponent(".config/repobar/secure")
        try FileManager.default.createDirectory(
            at: self.storageDirectory,
            withIntermediateDirectories: true
        )
    }
    
    public func store(_ data: Data, forKey key: String) throws {
        // TODO: Encrypt data before storing
        let filePath = self.storageDirectory.appendingPathComponent(key)
        try data.write(to: filePath)
    }
    
    public func retrieve(forKey key: String) throws -> Data? {
        let filePath = self.storageDirectory.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return nil
        }
        // TODO: Decrypt data after reading
        return try Data(contentsOf: filePath)
    }
    
    public func delete(forKey key: String) throws {
        let filePath = self.storageDirectory.appendingPathComponent(key)
        try FileManager.default.removeItem(at: filePath)
    }
}
#endif
```

## Browser Launcher Abstraction

```swift
// Sources/Platform/Protocol/BrowserLauncher.swift
import Foundation

public protocol BrowserLauncher {
    func openURL(_ url: URL) throws
}

#if os(macOS)
import AppKit

public final class MacOSBrowserLauncher: BrowserLauncher {
    public func openURL(_ url: URL) throws {
        NSWorkspace.shared.open(url)
    }
}
#endif

#if os(Linux)
public final class LinuxBrowserLauncher: BrowserLauncher {
    public func openURL(_ url: URL) throws {
        // Use xdg-open on Linux
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
        process.arguments = [url.absoluteString]
        try process.run()
    }
}
#endif
```

## Testing Platform Abstractions

```swift
// Tests/PlatformTests/PlatformTests.swift
import Testing
import Platform

@Suite
struct PlatformFactoryTests {
    @Test
    func testCreateSystemTray() {
        let tray = PlatformFactory.createSystemTray()
        #expect(tray != nil)
    }
    
    @Test
    func testCreateMenu() {
        let menu = PlatformFactory.createMenu(title: "Test")
        #expect(menu != nil)
        #expect(menu.items.isEmpty)
    }
    
    @Test
    func testCreateMenuItem() {
        let item = PlatformFactory.createMenuItem(title: "Test Item")
        #expect(item.title == "Test Item")
        #expect(item.isEnabled == true)
    }
    
    @Test
    func testMenuItemAction() {
        let item = PlatformFactory.createMenuItem(title: "Click Me")
        var actionCalled = false
        item.action = {
            actionCalled = true
        }
        item.action?()
        #expect(actionCalled == true)
    }
}
```

## Summary

These examples demonstrate:

1. **Protocol-based abstractions** - Define interfaces that work across platforms
2. **Conditional compilation** - Use `#if os(macOS)` and `#if os(Linux)` to include platform-specific code
3. **Type aliases** - Use `typealias` for platform-specific types (NSImage vs LinuxImage)
4. **Factory pattern** - Centralize platform-specific object creation
5. **Stubs for Linux** - Create placeholder implementations marked with TODO comments
6. **Testing** - Write tests that work across platforms

This approach allows the codebase to:
- Share as much code as possible
- Isolate platform differences
- Maintain type safety
- Support future platforms easily
- Keep the main application code platform-agnostic
