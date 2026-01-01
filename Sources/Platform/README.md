# Platform Abstraction Layer

This module provides cross-platform abstractions for RepoBar, enabling support for both macOS and Linux (KDE).

## Overview

The Platform module defines protocol-based abstractions for platform-specific functionality and provides concrete implementations for each supported platform. This allows the rest of RepoBar's codebase to work with platform-agnostic interfaces while the actual implementation details are handled by platform-specific code.

## Architecture

```
Platform/
├── Protocol/           # Platform-agnostic protocol definitions
│   ├── SystemTray.swift        # System tray/status bar abstraction
│   ├── PlatformMenu.swift      # Menu and menu item abstractions
│   ├── SecureStorage.swift     # Secure credential storage abstraction
│   ├── BrowserLauncher.swift   # Browser URL opening abstraction
│   └── PlatformTypes.swift     # Conditional type aliases (Image, Color)
│
├── macOS/              # macOS-specific implementations
│   ├── MacOSSystemTray.swift       # Wraps NSStatusBar/NSStatusItem
│   ├── MacOSPlatformMenu.swift     # Wraps NSMenu/NSMenuItem
│   ├── MacOSSecureStorage.swift    # Uses Keychain Services
│   └── MacOSBrowserLauncher.swift  # Uses NSWorkspace.open()
│
├── Linux/              # Linux-specific implementations
│   ├── LinuxSystemTray.swift       # StatusNotifierItem via D-Bus (TODO)
│   ├── LinuxPlatformMenu.swift     # DBusMenu protocol (TODO)
│   ├── LinuxSecureStorage.swift    # KWallet/libsecret (TODO)
│   └── LinuxBrowserLauncher.swift  # Uses xdg-open (implemented)
│
└── PlatformFactory.swift   # Factory for creating platform instances
```

## Protocols

### SystemTray
Abstracts system tray/status bar integration:
- `setIcon(_:)` - Set the tray icon
- `setMenu(_:)` - Set the tray menu
- `show()` / `hide()` - Control visibility
- `isVisible` - Check visibility state

**macOS**: Uses `NSStatusBar.system.statusItem()`  
**Linux**: Will use D-Bus StatusNotifierItem protocol

### PlatformMenu & PlatformMenuItem
Abstracts menu system:
- `addItem(_:)` - Add menu items
- `addSeparator()` - Add separator lines
- `removeAllItems()` - Clear the menu
- Menu item properties: title, enabled state, submenu, action, key equivalent, state

**macOS**: Wraps `NSMenu` and `NSMenuItem`  
**Linux**: Will implement DBusMenu protocol

### SecureStorage
Abstracts secure credential storage:
- `store(_:forKey:service:)` - Store credentials
- `retrieve(forKey:service:)` - Retrieve credentials
- `delete(forKey:service:)` - Delete credentials

**macOS**: Uses Keychain Services  
**Linux**: Will use KWallet (KDE) or libsecret (fallback)

### BrowserLauncher
Abstracts opening URLs in the default browser:
- `openURL(_:)` - Synchronously open URL
- `openURLAsync(_:)` - Asynchronously open URL

**macOS**: Uses `NSWorkspace.shared.open()`  
**Linux**: Uses `xdg-open` command

### PlatformTypes
Conditional type aliases for platform-specific types:
- `PlatformImage` - `NSImage` on macOS, custom struct on Linux
- `PlatformColor` - `NSColor` on macOS, custom struct on Linux

## Usage

### Using the Factory

The recommended way to create platform-specific instances:

```swift
import Platform

// Create instances using the factory
let systemTray = PlatformFactory.createSystemTray()
let menu = PlatformFactory.createMenu(title: "My Menu")
let menuItem = PlatformFactory.createMenuItem(title: "Action") {
    print("Menu item clicked!")
}
let secureStorage = PlatformFactory.createSecureStorage()
let browserLauncher = PlatformFactory.createBrowserLauncher()

// Use them with platform-agnostic code
systemTray.setMenu(menu)
menu.addItem(menuItem)
systemTray.show()

// Store and retrieve credentials
try? secureStorage.store("my-token", forKey: "github-token", service: "com.steipete.repobar")
if let token = try? secureStorage.retrieve(forKey: "github-token", service: "com.steipete.repobar") {
    print("Token: \(token)")
}

// Open URLs
_ = browserLauncher.openURL(URL(string: "https://github.com")!)
```

### Working with Protocol Types

You can write platform-agnostic code using the protocol types:

```swift
func setupTray(_ tray: SystemTray, menu: PlatformMenu) {
    let item = PlatformFactory.createMenuItem(title: "Refresh") {
        refreshData()
    }
    menu.addItem(item)
    tray.setMenu(menu)
    tray.show()
}
```

## Platform-Specific Code

When you need platform-specific behavior, use conditional compilation:

```swift
#if os(macOS)
// macOS-specific code
let macTray = tray as! MacOSSystemTray
let statusItem = macTray.underlyingStatusItem
#elseif os(Linux)
// Linux-specific code
let linuxTray = tray as! LinuxSystemTray
#endif
```

## Current Status (2026-01-01)

### ✅ Complete
- All protocol definitions
- All macOS implementations (wrapping existing AppKit functionality)
- Linux stub implementations
- PlatformFactory for cross-platform instantiation
- Builds successfully on both macOS and Linux

### 🚧 In Progress
- Linux implementations are currently stubs with TODO comments
- Need actual D-Bus integration for system tray and menus
- Need KWallet/libsecret integration for secure storage

### 📝 Future Work
- Implement D-Bus StatusNotifierItem for LinuxSystemTray
- Implement DBusMenu protocol for LinuxPlatformMenu
- Implement KWallet/libsecret for LinuxSecureStorage
- Add comprehensive tests for all implementations
- Migrate existing RepoBar code to use Platform abstractions
- Add platform-specific extensions as needed

## Testing

To build and test the Platform module:

```bash
# Build Platform target (works on both macOS and Linux)
swift build --target Platform

# Build the Linux placeholder app (Linux only)
swift build --product repobar-linux

# Run the Linux placeholder
.build/x86_64-unknown-linux-gnu/debug/repobar-linux
```

## Contributing

When adding new platform abstractions:

1. Define the protocol in `Protocol/`
2. Implement for macOS in `macOS/` (wrap existing AppKit code)
3. Implement for Linux in `Linux/` (even if just a stub with TODOs)
4. Add factory method to `PlatformFactory.swift`
5. Update this README
6. Add tests if possible

## References

### Linux Integration
- [StatusNotifierItem Specification](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/)
- [DBusMenu Protocol](https://github.com/AyatanaIndicators/libdbusmenu)
- [KWallet API](https://api.kde.org/frameworks/kwallet/html/)
- [libsecret Documentation](https://wiki.gnome.org/Projects/Libsecret)
- [XDG Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/)

### Swift & Linux
- [Swift on Linux](https://www.swift.org/download/#linux)
- [Swift Package Manager](https://github.com/apple/swift-package-manager)
- [Conditional Compilation in Swift](https://docs.swift.org/swift-book/ReferenceManual/Statements.html#ID538)

## License

Same as RepoBar (MIT)
