---
summary: "Linux/KDE port implementation plan: architecture analysis, platform abstractions, and cross-platform build strategy."
read_when:
  - Planning Linux port of RepoBar
  - Implementing platform-specific abstractions
  - Setting up cross-platform build system
---

# RepoBar Linux/KDE Port Implementation Plan

_Last updated: 2026-01-01_

## Executive Summary

RepoBar is currently a macOS-only menubar application built with Swift, SwiftUI, and AppKit. This document outlines the strategy and implementation plan for porting RepoBar to Linux with KDE integration, focusing on creating a system tray application that provides similar functionality to the macOS menubar app.

## Current Architecture Analysis

### Platform-Specific Dependencies

The current RepoBar implementation has significant macOS-specific dependencies:

#### Core macOS Frameworks Used:
- **AppKit**: Used extensively for menu system, status bar, alerts, and native controls
  - `NSMenu`, `NSMenuItem`, `NSStatusBar`, `NSStatusItem`
  - `NSApplication`, `NSWorkspace`, `NSRunningApplication`
  - `NSAlert`, `NSWindow`, `NSImage`, `NSColor`
  - `MenuBarExtra` (SwiftUI component for macOS menubar)
  
- **MenuBarExtraAccess**: Third-party package for enhanced menubar control
- **Sparkle**: Auto-update framework (macOS-specific)
- **Kingfisher**: Image loading/caching (cross-platform capable)
- **AppAuth-iOS**: OAuth library (cross-platform capable with modifications)

#### Files with Heavy macOS Dependencies:

**Core App Structure:**
- `Sources/RepoBar/App/RepoBarApp.swift` - Main app entry using `MenuBarExtra` and `NSApplicationDelegateAdaptor`
- `Sources/RepoBar/StatusBar/*.swift` - Entire StatusBar module uses `NSMenu` and AppKit

**Settings & UI:**
- `Sources/RepoBar/Settings/*.swift` - Uses `NSApplication` and AppKit controls
- `Sources/RepoBar/Auth/OAuthCoordinator.swift` - Uses `NSWorkspace` for browser launching
- `Sources/RepoBar/Views/*.swift` - Mixed SwiftUI/AppKit views

**Support Utilities:**
- `Sources/RepoBar/Support/LaunchAtLoginHelper.swift` - Uses `SMAppService` (macOS-specific)
- `Sources/RepoBar/Support/TerminalApp.swift` - Uses `NSWorkspace` and AppleScript
- `Sources/RepoBar/Support/NSImage+Resize.swift` - Uses `NSImage` API
- `Sources/RepoBar/Support/NSColor+Contrast.swift` - Uses `NSColor` API

### Cross-Platform Capable Components

The following components are already platform-agnostic or can be easily made so:

#### RepoBarCore Module:
- **API/GitHub Integration**: All GraphQL and REST API code is platform-agnostic
- **Models**: Pure Swift data structures
- **Authentication Core**: Token management and PKCE flow logic (OAuth coordination layer needs work)

#### CLI (repobarcli):
- Already designed to be cross-platform
- Uses Foundation and cross-platform dependencies
- Can serve as reference for platform-agnostic patterns

## Linux/KDE Port Strategy

### Phase 1: Platform Abstraction Layer

Create a platform abstraction layer to isolate macOS-specific code and enable Linux implementations.

#### 1.1 Define Platform Protocols

Create protocol-based abstractions for platform-specific functionality:

```swift
// Sources/RepoBar/Platform/SystemTray.swift
protocol SystemTray {
    func setIcon(_ image: PlatformImage)
    func setMenu(_ menu: PlatformMenu)
    func show()
    func hide()
}

// Sources/RepoBar/Platform/PlatformMenu.swift
protocol PlatformMenu {
    func addItem(_ item: PlatformMenuItem)
    func addSeparator()
    func removeAllItems()
    func show(at point: CGPoint?)
}

protocol PlatformMenuItem {
    var title: String { get set }
    var isEnabled: Bool { get set }
    var submenu: PlatformMenu? { get set }
    var action: (() -> Void)? { get set }
}

// Sources/RepoBar/Platform/PlatformTypes.swift
#if os(macOS)
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
#elseif os(Linux)
typealias PlatformImage = LinuxImage
typealias PlatformColor = LinuxColor
#endif
```

#### 1.2 macOS Implementation

Move existing macOS code into concrete implementations:

```swift
// Sources/RepoBar/Platform/macOS/MacOSSystemTray.swift
#if os(macOS)
import AppKit

final class MacOSSystemTray: SystemTray {
    private let statusItem: NSStatusItem
    // ... existing implementation
}
#endif
```

#### 1.3 Linux Implementation

Create Linux implementations using appropriate libraries:

**Option A: Qt/KDE Integration (Recommended for KDE)**
- Use Swift-Qt bindings or create Swift wrappers
- Native KDE system tray integration
- Best visual integration with KDE desktop

**Option B: GTK/libappindicator**
- More widely supported across Linux desktops
- Uses system tray protocol
- Cross-desktop compatibility

**Option C: Pure D-Bus Implementation**
- Direct D-Bus communication for StatusNotifierItem
- No additional GUI framework dependencies
- More manual but lightweight

### Phase 2: Build System Updates

#### 2.1 Update Package.swift

```swift
// Package.swift additions
let package = Package(
    name: "RepoBar",
    platforms: [
        .macOS(.v15),
        .iOS(.v26),
        .linux, // Add Linux support
    ],
    products: [
        .library(name: "RepoBarCore", targets: ["RepoBarCore"]),
        .executable(name: "repobarcli", targets: ["repobarcli"]),
        .executable(name: "repobar-linux", targets: ["repobar-linux"]), // New Linux target
    ],
    dependencies: [
        // Existing dependencies...
        // Linux-specific dependencies:
        .package(url: "https://github.com/...", .upToNextMajor(from: "1.0.0")), // Linux UI toolkit
    ],
    targets: [
        // Existing targets...
        .executableTarget(
            name: "repobar-linux",
            dependencies: [
                "RepoBarCore",
                "Platform", // New platform abstraction module
                // Linux-specific dependencies
            ],
            path: "Sources/repobar-linux"
        ),
        .target(
            name: "Platform",
            dependencies: [],
            path: "Sources/Platform"
        ),
    ]
)
```

#### 2.2 Conditional Compilation

Use Swift's conditional compilation for platform-specific code:

```swift
#if os(macOS)
    // macOS-specific implementation
#elseif os(Linux)
    // Linux-specific implementation
#else
    #error("Unsupported platform")
#endif
```

#### 2.3 Build Scripts

Create Linux-specific build scripts:

```bash
# Scripts/build-linux.sh
#!/bin/bash
set -euo pipefail

echo "Building RepoBar for Linux..."
swift build --product repobar-linux

echo "Creating AppImage or .deb package..."
# Package creation logic
```

### Phase 3: Linux-Specific Features

#### 3.1 System Tray Integration

Implement StatusNotifierItem protocol for modern Linux desktops:

```swift
// Sources/repobar-linux/LinuxSystemTray.swift
#if os(Linux)
import Foundation
import DBus // Or appropriate library

final class LinuxSystemTray: SystemTray {
    private let dbusConnection: DBusConnection
    
    func setIcon(_ image: PlatformImage) {
        // Implement using D-Bus StatusNotifierItem
    }
    
    func setMenu(_ menu: PlatformMenu) {
        // Implement DBusMenu protocol
    }
}
#endif
```

#### 3.2 Desktop Integration

```swift
// .desktop file for application launcher
[Desktop Entry]
Type=Application
Name=RepoBar
GenericName=GitHub Repository Monitor
Comment=Monitor GitHub repositories from your system tray
Exec=/usr/bin/repobar
Icon=repobar
Terminal=false
Categories=Development;
```

#### 3.3 Auto-start Configuration

Replace macOS `SMAppService` with Linux autostart:

```swift
// Sources/Platform/Linux/LinuxAutostart.swift
#if os(Linux)
struct LinuxAutostart {
    static func enable() {
        // Copy .desktop file to ~/.config/autostart/
        let autostartPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/autostart/repobar.desktop")
        // ... implementation
    }
}
#endif
```

### Phase 4: UI Adaptation

#### 4.1 Menu System

The menu system is the core UI component that needs adaptation:

**Challenges:**
- macOS uses NSMenu with rich SwiftUI view integration
- Linux needs menu protocol implementation (DBusMenu for system tray)
- Different rendering capabilities

**Solutions:**
1. Abstract menu building logic from rendering
2. Create platform-specific menu renderers
3. Support reduced feature set on Linux initially (no custom SwiftUI views in menus)

#### 4.2 Settings Window

**Options:**
1. **Qt-based UI** - Native KDE look and feel
2. **GTK-based UI** - GNOME-style but works on KDE
3. **Web-based UI** - HTML/CSS/JS served locally (most portable)
4. **Terminal UI** - For initial development, use CLI for settings

#### 4.3 Notifications

Replace macOS notification center:

```swift
#if os(Linux)
import DBus

struct LinuxNotificationCenter {
    static func post(title: String, body: String) {
        // Use org.freedesktop.Notifications D-Bus interface
    }
}
#endif
```

### Phase 5: Dependencies Management

#### 5.1 Replace macOS-Only Dependencies

| macOS Dependency | Linux Alternative | Notes |
|-----------------|-------------------|-------|
| MenuBarExtraAccess | StatusNotifierItem | D-Bus protocol |
| Sparkle | AppImageUpdate or custom | Manual update check + download |
| AppAuth browser launch | xdg-open | Use system default browser |
| Keychain | libsecret or KWallet | KDE wallet integration |
| NSWorkspace | xdg-open, dbus | File/URL opening |

#### 5.2 Update SwiftPM Dependencies

Add Linux-compatible alternatives:
- Remove or conditionalize macOS-only packages
- Add Linux UI toolkit packages
- Add D-Bus bindings if needed

### Phase 6: Testing Strategy

#### 6.1 Development Environment

Set up Linux development environment:
- KDE Neon or Kubuntu VM/container
- Swift 6.2+ installed
- Required Linux development libraries
- D-Bus development tools

#### 6.2 Testing Checklist

- [ ] Core RepoBarCore functionality (API, auth, models)
- [ ] System tray icon appears
- [ ] Menu displays correctly
- [ ] OAuth flow works (browser opens, callback handled)
- [ ] Repository data fetches and displays
- [ ] Settings can be configured
- [ ] Auto-start functionality
- [ ] Notifications work
- [ ] CLI tool works on Linux

### Phase 7: Documentation

#### 7.1 Build Documentation

Create `docs/building-linux.md`:
- System requirements
- Installing Swift on Linux
- Installing dependencies (Qt, GTK, or D-Bus libraries)
- Building from source
- Packaging instructions

#### 7.2 User Documentation

Update README.md:
- Add Linux installation instructions
- Document Linux-specific features and limitations
- Add screenshots of Linux version

## Implementation Priorities

### Minimal Viable Port (MVP)

Focus on getting basic functionality working:

1. **Core functionality** (RepoBarCore) - should work as-is
2. **CLI tool** - should work as-is or with minimal changes
3. **Basic system tray** - icon in system tray
4. **Simple menu** - text-based menu items (no custom views initially)
5. **Settings via CLI** - defer GUI settings to later
6. **OAuth flow** - browser-based auth with loopback server

### Full Feature Parity

After MVP, add:
1. Rich menu items with repository information
2. GUI settings window
3. Desktop notifications
4. Auto-start configuration
5. System integration (file manager, terminal)
6. Update mechanism

## Technical Challenges & Solutions

### Challenge 1: Menu Rendering

**Problem**: macOS allows embedding custom SwiftUI views in NSMenu.
**Solution**: 
- Phase 1: Use text-only menu items on Linux
- Phase 2: Create custom menu rendering using chosen UI toolkit
- Phase 3: Consider web-based menu rendering for rich content

### Challenge 2: Secure Storage

**Problem**: macOS Keychain not available on Linux.
**Solution**:
- KWallet integration for KDE
- libsecret as fallback
- Encrypted file storage as last resort

### Challenge 3: OAuth Callback

**Problem**: Custom URL scheme handling differs on Linux.
**Solution**:
- Continue using loopback HTTP server (should work on Linux)
- Register .desktop file with x-scheme-handler MIME type
- Fall back to manual token paste if needed

### Challenge 4: Build and Distribution

**Problem**: No standard Linux app distribution like macOS .app bundles.
**Solution**:
- Create AppImage (universal Linux package)
- Create .deb for Debian/Ubuntu/KDE Neon
- Create .rpm for Fedora/openSUSE
- Provide Flatpak for broader distribution

## Recommended Implementation Approach

### Option 1: Qt/KDE Native (Recommended for KDE focus)

**Pros:**
- Best KDE integration
- Native look and feel
- Rich UI capabilities
- Good Swift interop possible

**Cons:**
- Additional dependency (Qt)
- More complex build setup
- Qt license considerations

### Option 2: Terminal/CLI-First Approach (Recommended for MVP)

**Pros:**
- Fastest to implement
- Leverages existing CLI code
- No GUI framework dependencies
- Focus on core functionality

**Cons:**
- Limited UI
- Not a true "menubar" equivalent
- May not meet user expectations

**Path forward:**
1. Start with CLI-first approach to validate core functionality
2. Add basic system tray (icon only)
3. Incrementally add GUI components
4. Eventually transition to full GUI with Qt/KDE

## File Structure for Linux Port

```
Sources/
├── Platform/
│   ├── Protocol/
│   │   ├── SystemTray.swift
│   │   ├── PlatformMenu.swift
│   │   └── PlatformTypes.swift
│   ├── macOS/
│   │   ├── MacOSSystemTray.swift
│   │   └── MacOSPlatformSupport.swift
│   └── Linux/
│       ├── LinuxSystemTray.swift
│       ├── LinuxPlatformSupport.swift
│       └── DBus/
│           ├── StatusNotifierItem.swift
│           └── DBusMenu.swift
├── repobar-linux/
│   ├── main.swift
│   ├── LinuxApp.swift
│   └── LinuxMenuBuilder.swift
└── RepoBarCore/
    └── (unchanged - platform agnostic)
```

## Next Steps

1. **Validate approach** - Get stakeholder buy-in on Linux port strategy
2. **Set up development environment** - Linux VM with KDE and Swift
3. **Create platform abstraction layer** - Define protocols and interfaces
4. **Implement Linux system tray** - Basic icon in system tray
5. **Port core app** - Get basic menu working
6. **Test and iterate** - Fix Linux-specific issues
7. **Package and distribute** - Create installation packages
8. **Document** - Update docs for Linux users

## Resources

### Swift on Linux
- [Swift.org - Linux Support](https://www.swift.org/download/#linux)
- [Swift Package Manager on Linux](https://github.com/apple/swift-package-manager)

### Linux System Tray
- [StatusNotifierItem Specification](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/)
- [DBusMenu Protocol](https://github.com/AyatanaIndicators/libdbusmenu)

### KDE Development
- [KDE Developer Documentation](https://develop.kde.org/)
- [Qt for Linux](https://doc.qt.io/qt-6/linux.html)

### Swift GUI Options for Linux
- [SwiftGtk](https://github.com/rhx/SwiftGtk)
- [Swift-Qt](https://github.com/Fueled/swift-qt)

## Conclusion

Porting RepoBar to Linux/KDE is feasible but requires significant effort due to the heavy reliance on macOS-specific UI frameworks. The recommended approach is:

1. Start with a CLI-first MVP to validate core functionality
2. Add basic system tray support using D-Bus
3. Incrementally add GUI features using Qt/KDE for best integration
4. Maintain platform abstraction to keep codebase maintainable

The existing RepoBarCore module provides a solid foundation as it's already platform-agnostic. The primary work involves replacing the AppKit-based UI layer with Linux equivalents.
