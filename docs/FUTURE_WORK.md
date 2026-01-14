# Future Work for RepoBar Linux Port

_Last updated: 2026-01-01_

## Overview

The foundation is complete! The Platform abstraction layer is implemented and working on both macOS and Linux. This document outlines the future work needed to achieve full Linux/KDE functionality.

## Status Summary

### ✅ Completed (2026-01-01)
- Platform abstraction protocols defined (`SystemTray`, `PlatformMenu`, `SecureStorage`, `BrowserLauncher`)
- macOS implementations wrapping existing AppKit functionality
- Linux stub implementations with TODO markers
- `Platform` target builds successfully on both macOS and Linux
- `repobar-linux` placeholder executable

### 🚧 Current Blockers
1. **apollo-ios Linux Support** - Prevents RepoBarCore from building on Linux
2. **D-Bus Integration** - Required for system tray, menus, and desktop integration
3. **Secure Storage** - Need KWallet or libsecret integration

## Future Tasks

### Task 1: Implement D-Bus Integrations

#### 1.1 StatusNotifierItem Protocol (System Tray)

**Goal**: Make LinuxSystemTray functional using D-Bus StatusNotifierItem protocol

**Implementation Steps**:
1. Add D-Bus dependency to Package.swift (e.g., swift-dbus or custom bindings)
2. Implement D-Bus connection management in LinuxSystemTray
3. Register StatusNotifierItem on session bus
4. Implement icon property (IconPixmap or IconName)
5. Implement menu export via DBusMenu
6. Handle activation signals from the system tray

**Required D-Bus Interfaces**:
- `org.kde.StatusNotifierItem` - Main system tray protocol
- Properties: Status, IconName/IconPixmap, Menu, ToolTip
- Methods: Activate, SecondaryActivate, Scroll
- Signals: NewIcon, NewToolTip, NewStatus

**Resources**:
- [StatusNotifierItem Specification](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/)
- [KDE StatusNotifierItem API](https://api.kde.org/frameworks/knotifications/html/classKStatusNotifierItem.html)

**Testing**:
- Icon appears in KDE system tray
- Clicking icon triggers activation
- Tooltip displays correctly

#### 1.2 DBusMenu Protocol (Menu System)

**Goal**: Make LinuxPlatformMenu functional using DBusMenu protocol

**Implementation Steps**:
1. Implement DBusMenu server in LinuxPlatformMenu
2. Export menu structure via D-Bus
3. Handle menu item property updates
4. Implement event handling (ItemActivated signal)
5. Support menu item types: standard, separator, submenu
6. Implement dynamic menu updates

**Required D-Bus Interfaces**:
- `com.canonical.dbusmenu` - Menu protocol
- Methods: GetLayout, GetGroupProperties, Event, AboutToShow
- Signals: LayoutUpdated, ItemsPropertiesUpdated
- Properties: Version, TextDirection, Status

**Menu Item Properties**:
- `label` - Menu item text
- `enabled` - Whether item is clickable
- `visible` - Whether item is shown
- `icon-name` - Icon identifier
- `children-display` - For submenus
- `toggle-type` - For checkboxes/radio buttons
- `toggle-state` - Current toggle state

**Resources**:
- [DBusMenu Protocol](https://github.com/AyatanaIndicators/libdbusmenu)
- [DBusMenu Specification](https://github.com/AyatanaIndicators/libdbusmenu/blob/master/libdbusmenu-glib/dbus-menu.xml)

**Testing**:
- Menu displays with correct text items
- Menu item actions trigger callbacks
- Submenus work correctly
- Separators render properly
- Dynamic updates work (add/remove items)

#### 1.3 Desktop Integration

**Additional D-Bus Integrations**:

**Notifications** (`org.freedesktop.Notifications`):
```swift
// Implement Linux notification support
func postNotification(title: String, body: String, icon: String?) {
    // Call Notify method on org.freedesktop.Notifications
}
```

**File Manager** (`org.freedesktop.FileManager1`):
```swift
// Open files in file manager
func showInFileManager(path: String) {
    // Call ShowItems method
}
```

**D-Bus Dependencies**:
- Consider using [PADL/swift-dbus](https://github.com/PADL/swift-dbus)
- Or create minimal D-Bus bindings for required interfaces
- Alternatively, use GDBus via C interop

### Task 2: Fix apollo-ios Linux Support

**Problem**: apollo-ios doesn't import FoundationNetworking on Linux, causing build failures

**Impact**: Blocks RepoBarCore target from building on Linux

**Options**:

#### Option A: Fork and Patch (Recommended for MVP)
1. Fork apollo-ios repository
2. Add `#if canImport(FoundationNetworking)` imports where needed
3. Test on Linux
4. Update Package.swift to use forked version
5. Submit upstream PR to apollo-ios

**Files Likely Needing Changes**:
```swift
// Add to affected apollo-ios files
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
```

#### Option B: Alternative GraphQL Client
- Evaluate [Graphaello](https://github.com/nerdsupremacist/Graphaello)
- Evaluate creating custom GraphQL client
- Requires rewriting API layer in RepoBarCore

#### Option C: Wait for Upstream
- Report issue to apollo-ios maintainers
- Track progress on apollo-ios repository
- May take significant time

**Recommended Approach**: Option A (fork and patch) for immediate progress, with Option C (upstream PR) for long-term sustainability

**Action Items**:
1. Identify all apollo-ios files needing FoundationNetworking import
2. Create fork with necessary changes
3. Test build on Linux
4. Update Package.swift dependency URL
5. Document the fork and patches applied
6. Submit PR to apollo-ios upstream

### Task 3: Implement Secure Storage

**Goal**: Make LinuxSecureStorage functional using KWallet or libsecret

#### 3.1 KWallet Integration (KDE Primary)

**Implementation**:
1. Detect if running in KDE environment (check `XDG_CURRENT_DESKTOP`)
2. Use D-Bus to communicate with KWallet daemon
3. Implement wallet opening and locking
4. Store/retrieve passwords from wallet

**D-Bus Interface**:
- Service: `org.kde.kwalletd5`
- Interface: `org.kde.KWallet`
- Methods: `open`, `writePassword`, `readPassword`, `removeEntry`

**Example Flow**:
```swift
// Open wallet
let walletName = "kdewallet" // default KDE wallet
let handle = dbusCall("org.kde.KWallet.open", walletName, 0)

// Write password
dbusCall("org.kde.KWallet.writePassword", handle, folder, key, value, appId)

// Read password  
let value = dbusCall("org.kde.KWallet.readPassword", handle, folder, key, appId)
```

**Resources**:
- [KWallet D-Bus API](https://api.kde.org/frameworks/kwallet/html/classKWallet_1_1Wallet.html)

#### 3.2 libsecret Integration (Fallback)

**Implementation**:
1. Detect libsecret availability
2. Use C interop to call libsecret functions
3. Store secrets with appropriate schema

**Required C Functions**:
```c
secret_password_store_sync()
secret_password_lookup_sync()
secret_password_clear_sync()
```

**Swift Interop**:
- Use `@_extern(c)` or create Swift modulemap
- Or use Process to call `secret-tool` command-line utility

**Resources**:
- [libsecret Documentation](https://wiki.gnome.org/Projects/Libsecret)
- [secret-tool man page](https://manpages.ubuntu.com/manpages/focal/man1/secret-tool.1.html)

#### 3.3 Fallback: Encrypted File Storage

**Implementation**:
1. Create encrypted file in `~/.config/repobar/`
2. Use system keyring password or prompt user
3. Encrypt using CryptoKit

**Note**: This is less secure than KWallet/libsecret but provides last-resort functionality

### Task 4: Migrate Existing Code to Platform Abstractions

**Goal**: Refactor existing RepoBar codebase to use Platform abstractions instead of direct AppKit calls

#### 4.1 StatusBar Module Migration

**Current State**: Uses NSStatusBar, NSMenu, NSMenuItem directly

**Target State**: Uses Platform protocols

**Files to Migrate**:
- `Sources/RepoBar/StatusBar/StatusBarController.swift`
- `Sources/RepoBar/StatusBar/MenuBuilder.swift`
- All files in `Sources/RepoBar/StatusBar/`

**Migration Pattern**:
```swift
// Before:
import AppKit
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
let menu = NSMenu()
statusItem.menu = menu

// After:
import Platform
let systemTray = PlatformFactory.createSystemTray()
let menu = PlatformFactory.createMenu()
systemTray.setMenu(menu)
systemTray.show()
```

#### 4.2 OAuth/Auth Migration

**Files to Migrate**:
- `Sources/RepoBar/Auth/OAuthCoordinator.swift`
- Browser launch code using NSWorkspace

**Migration Pattern**:
```swift
// Before:
import AppKit
NSWorkspace.shared.open(authURL)

// After:
import Platform
let browserLauncher = PlatformFactory.createBrowserLauncher()
try await browserLauncher.openURLAsync(authURL)
```

#### 4.3 Token Storage Migration

**Files to Migrate**:
- `Sources/RepoBarCore/Auth/TokenStore.swift`
- Keychain access code

**Migration Pattern**:
```swift
// Before:
// Direct Keychain API calls

// After:
import Platform
let storage = PlatformFactory.createSecureStorage()
try storage.store(token, forKey: "github-token", service: "com.steipete.repobar")
```

#### 4.4 Migration Strategy

**Approach**:
1. Start with least intrusive changes
2. Create wrapper layer that uses Platform protocols internally
3. Gradually migrate existing code file by file
4. Maintain macOS functionality throughout
5. Test on macOS after each migration step

**Conditional Compilation Strategy**:
```swift
// Keep macOS-specific optimizations where needed
#if os(macOS)
    // Use AppKit-specific features (custom views, etc.)
#else
    // Use platform-agnostic approach
#endif
```

**Testing**:
- Run full test suite after each file migration
- Verify macOS app still works correctly
- Check that Platform abstractions are being used

### Task 5: Create Linux Packages

**Goal**: Provide distributable packages for Linux users

#### 5.1 AppImage (Universal Linux Package)

**Steps**:
1. Create `AppImageBuilder.yml` or use `appimagetool`
2. Bundle repobar-linux executable
3. Include all dependencies (Swift runtime, libraries)
4. Create .desktop file for integration
5. Include icon in appropriate resolutions

**AppImage Structure**:
```
RepoBar.AppImage/
├── AppRun (launcher script)
├── repobar-linux (executable)
├── usr/
│   ├── bin/
│   │   └── repobar-linux
│   ├── lib/ (Swift runtime, dependencies)
│   └── share/
│       ├── applications/
│       │   └── repobar.desktop
│       └── icons/
│           └── hicolor/
│               └── 256x256/
│                   └── repobar.png
└── repobar.desktop
```

**Build Script** (`Scripts/build-appimage.sh`):
```bash
#!/bin/bash
# Download appimagetool
# Build repobar-linux in release mode
# Copy to AppImage directory structure
# Bundle Swift runtime
# Run appimagetool
```

**Resources**:
- [AppImage Documentation](https://docs.appimage.org/)
- [AppImage Best Practices](https://docs.appimage.org/packaging-guide/index.html)

#### 5.2 .deb Package (Debian/Ubuntu/KDE Neon)

**Steps**:
1. Create `debian/` directory with control files
2. Define package metadata (name, version, dependencies)
3. Create installation scripts (postinst, prerm)
4. Build with `dpkg-deb`

**Debian Package Structure**:
```
repobar_0.1.0_amd64/
├── DEBIAN/
│   ├── control
│   ├── postinst
│   └── prerm
├── usr/
│   ├── bin/
│   │   └── repobar
│   └── share/
│       ├── applications/
│       │   └── repobar.desktop
│       ├── icons/
│       └── doc/
│           └── repobar/
└── etc/
    └── repobar/
```

**control file**:
```
Package: repobar
Version: 0.1.0
Architecture: amd64
Maintainer: RepoBar Team <contact@example.com>
Depends: libc6, libdbus-1-3
Description: GitHub repository monitor for Linux
 RepoBar provides system tray integration for monitoring
 GitHub repositories on KDE Plasma and other Linux desktops.
```

**Build Script** (`Scripts/build-deb.sh`)

#### 5.3 .rpm Package (Fedora/openSUSE)

**Steps**:
1. Create `.spec` file
2. Define RPM metadata
3. Build with `rpmbuild`

**Spec File** (`repobar.spec`):
```spec
Name:           repobar
Version:        0.1.0
Release:        1%{?dist}
Summary:        GitHub repository monitor
License:        MIT
URL:            https://github.com/steipete/RepoBar

%description
RepoBar provides system tray integration for monitoring
GitHub repositories on KDE Plasma and other Linux desktops.

%install
# Installation commands

%files
/usr/bin/repobar
/usr/share/applications/repobar.desktop
/usr/share/icons/hicolor/256x256/apps/repobar.png

%changelog
* Wed Jan 01 2026 RepoBar Team <contact@example.com> - 0.1.0-1
- Initial Linux release
```

**Build Script** (`Scripts/build-rpm.sh`)

#### 5.4 Desktop Entry File

**repobar.desktop**:
```desktop
[Desktop Entry]
Type=Application
Name=RepoBar
GenericName=GitHub Repository Monitor
Comment=Monitor GitHub repositories from your system tray
Exec=/usr/bin/repobar
Icon=repobar
Terminal=false
Categories=Development;RevisionControl;
Keywords=github;git;repository;development;
StartupNotify=false
X-DBUS-StartupType=None
```

**Installation Locations**:
- System: `/usr/share/applications/repobar.desktop`
- User: `~/.local/share/applications/repobar.desktop`
- Autostart: `~/.config/autostart/repobar.desktop`

### Task 6: Testing and Validation

#### 6.1 Manual Testing Checklist

**System Tray**:
- [ ] Icon appears in system tray
- [ ] Icon can be clicked
- [ ] Tooltip displays correctly
- [ ] Icon updates when data changes

**Menu System**:
- [ ] Menu opens when icon is clicked
- [ ] Menu items display with correct text
- [ ] Menu items respond to clicks
- [ ] Submenus work correctly
- [ ] Separators display correctly
- [ ] Menu updates dynamically

**Authentication**:
- [ ] OAuth browser flow opens browser
- [ ] Callback URL is received
- [ ] Token is stored securely
- [ ] Token can be retrieved
- [ ] Token refresh works

**GitHub API**:
- [ ] Repository list loads
- [ ] Repository details display
- [ ] CI status shows correctly
- [ ] Activity feed populates
- [ ] Rate limiting is respected

**Distribution**:
- [ ] AppImage runs on multiple distros
- [ ] .deb installs on Ubuntu/Debian
- [ ] .rpm installs on Fedora/openSUSE
- [ ] Desktop entry appears in launcher
- [ ] Autostart works when enabled

#### 6.2 Test Distributions

**Recommended Test Targets**:
- KDE Neon (latest) - Primary KDE target
- Kubuntu 24.04 LTS - Long-term support
- Fedora KDE Spin (latest) - RPM-based
- openSUSE Tumbleweed KDE - Rolling release
- Arch Linux with KDE - Cutting edge

#### 6.3 Automated Testing

**Unit Tests**:
- Platform abstraction protocol compliance
- D-Bus message formatting
- Menu structure building
- Secure storage operations

**Integration Tests**:
- System tray registration
- Menu display and interaction
- OAuth flow end-to-end
- GitHub API calls

## Implementation Priority

### Phase 1: Core Functionality (MVP)
1. Fix apollo-ios for Linux (fork and patch)
2. Implement basic D-Bus StatusNotifierItem
3. Implement basic DBusMenu protocol
4. Get icon in system tray with simple text menu

### Phase 2: Feature Completion
1. Implement secure storage (KWallet + libsecret)
2. Complete D-Bus integrations (notifications, etc.)
3. Migrate existing code to use Platform abstractions
4. Full feature parity with macOS version

### Phase 3: Distribution
1. Create AppImage package
2. Create .deb package
3. Create .rpm package
4. Set up CI/CD for Linux builds
5. Documentation and user guides

## Resources and Dependencies

### Required Linux Packages (Development)
```bash
# D-Bus development
sudo apt install libdbus-1-dev

# KWallet development (optional)
sudo apt install libkf5wallet-dev

# libsecret development (optional)
sudo apt install libsecret-1-dev

# AppImage tools
sudo apt install appimagetool

# Packaging tools
sudo apt install debhelper rpm
```

### Swift Dependencies to Add
```swift
// Package.swift additions
.package(url: "https://github.com/PADL/swift-dbus", from: "1.0.0"),
```

### Documentation to Create
- [ ] `docs/building-linux.md` - Update with D-Bus requirements
- [ ] `docs/linux-development.md` - Development guide for Linux features
- [ ] `docs/linux-packaging.md` - Packaging guide for distributors
- [ ] `docs/linux-troubleshooting.md` - Common issues and solutions

## Success Criteria

**Milestone 1: Foundation Ready** ✅ (Completed 2026-01-01)
- Platform abstraction layer complete
- Builds on Linux
- Basic executable runs

**Milestone 2: Core Functional**
- System tray icon appears
- Menu displays and responds to clicks
- OAuth flow works
- GitHub API calls succeed

**Milestone 3: Feature Complete**
- All Platform abstractions implemented
- Existing code migrated
- Feature parity with macOS (except custom menu views)
- Secure storage works

**Milestone 4: Distributable**
- AppImage package created
- .deb package created
- .rpm package created
- Tested on multiple distributions
- Documentation complete

## Contributing

See [docs/LINUX_PORT_TRACKING.md](./LINUX_PORT_TRACKING.md) for overall progress tracking.

For specific tasks:
1. Check the task list above
2. Create an issue for the specific task
3. Reference this document in your PR
4. Test on actual Linux system
5. Update documentation as you go

## Contact

For questions about Linux port development:
- Open an issue on GitHub
- Tag with `linux-port` label
- Reference this future work document
