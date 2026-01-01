---
summary: "Building RepoBar on Linux: requirements, known issues, and workarounds for cross-platform compilation."
read_when:
  - Attempting to build RepoBar on Linux
  - Troubleshooting Linux build issues
  - Setting up Linux development environment
---

# Building RepoBar on Linux

_Last updated: 2026-01-01_

## Current Status

**⚠️ Work in Progress**: RepoBar is currently a macOS-only application. This document tracks the progress and challenges of porting it to Linux/KDE.

### What Works
- ✅ Swift 6.2+ is available on Linux
- ✅ Most Swift Package Manager dependencies can be fetched
- ✅ Core Foundation types are available

### Known Issues
1. **Apollo iOS dependency** - Does not properly import `FoundationNetworking` on Linux
   - Missing: `URLRequest`, `HTTPURLResponse`, `URLSession.AsyncBytes`
   - These types require `import FoundationNetworking` on Linux
   - Upstream issue: apollo-ios doesn't add the required import

2. **macOS-specific UI frameworks** - Heavy reliance on AppKit
   - `NSMenu`, `NSStatusBar`, `NSMenuItem` (no Linux equivalents)
   - `MenuBarExtra` (SwiftUI macOS-only component)
   - `MenuBarExtraAccess` third-party library (macOS-only)

3. **macOS-specific APIs** 
   - `NSWorkspace` (launching apps, opening URLs)
   - `SMAppService` (launch at login)
   - Sparkle auto-update framework
   - Keychain Services (secure storage)

## System Requirements

### Linux Distribution
Recommended:
- **KDE Neon** (latest)
- **Kubuntu** 24.04 LTS or later
- **Fedora KDE Spin** 40+
- **openSUSE Tumbleweed** with KDE Plasma

Any modern Linux distribution with:
- KDE Plasma 5.27+ or 6.0+
- System tray support (StatusNotifierItem)
- D-Bus

### Development Tools

#### Required
- **Swift 6.2 or later**
  - Download from: https://www.swift.org/download/
  - Or use swiftenv/swiftly for version management

- **Git** 2.40+
  ```bash
  sudo apt install git  # Debian/Ubuntu
  sudo dnf install git  # Fedora
  ```

- **Build essentials**
  ```bash
  # Debian/Ubuntu/KDE Neon
  sudo apt install build-essential clang libsqlite3-dev libncurses5-dev
  
  # Fedora
  sudo dnf install gcc-c++ clang sqlite-devel ncurses-devel
  ```

#### Optional (for GUI development)
- **Qt development libraries** (if using Qt for GUI)
  ```bash
  # Debian/Ubuntu
  sudo apt install qtbase5-dev qtdeclarative5-dev
  
  # Fedora
  sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel
  ```

- **GTK development libraries** (alternative to Qt)
  ```bash
  # Debian/Ubuntu
  sudo apt install libgtk-3-dev
  
  # Fedora
  sudo dnf install gtk3-devel
  ```

- **D-Bus development libraries**
  ```bash
  # Debian/Ubuntu
  sudo apt install libdbus-1-dev
  
  # Fedora
  sudo dnf install dbus-devel
  ```

## Installing Swift on Linux

### Option 1: Official Swift.org Binaries

```bash
# Download Swift 6.2 (adjust URL for latest version)
wget https://download.swift.org/swift-6.2.3-release/ubuntu2404/swift-6.2.3-RELEASE/swift-6.2.3-RELEASE-ubuntu24.04.tar.gz

# Extract
tar xzf swift-6.2.3-RELEASE-ubuntu24.04.tar.gz

# Move to /opt
sudo mv swift-6.2.3-RELEASE-ubuntu24.04 /opt/swift

# Add to PATH in ~/.bashrc or ~/.zshrc
echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify
swift --version
```

### Option 2: Swiftly (Recommended)

```bash
# Install swiftly
curl -L https://swift-server.github.io/swiftly/swiftly-install.sh | bash

# Install Swift 6.2
swiftly install 6.2

# Use it
swiftly use 6.2
```

## Current Build Attempts

### Attempt 1: Build RepoBarCore

```bash
cd RepoBar
swift build --target RepoBarCore
```

**Result**: ❌ Fails due to apollo-ios missing `FoundationNetworking` import

**Error messages**:
```
error: cannot find type 'URLRequest' in scope
error: 'HTTPURLResponse' is unavailable: This type has moved to the FoundationNetworking module
error: 'AsyncBytes' is not a member type of type 'Foundation.URLSession'
```

### Attempt 2: Build repobarcli

```bash
cd RepoBar
swift build --target repobarcli
```

**Result**: ❌ Fails due to RepoBarCore dependency (same apollo-ios issue)

## Workarounds

### Temporary Fix: Patch apollo-ios

We need to add `import FoundationNetworking` to apollo-ios files when building on Linux.

**Option A: Fork and patch apollo-ios**
1. Fork apollo-ios repository
2. Add conditional imports:
   ```swift
   #if canImport(FoundationNetworking)
   import FoundationNetworking
   #endif
   ```
3. Update Package.swift to use forked version

**Option B: Use local package override**
1. Clone apollo-ios locally
2. Add required imports
3. Update Package.swift with local path override:
   ```swift
   dependencies: [
       .package(path: "../apollo-ios-linux"),  // Local patched version
   ]
   ```

### Building without Apollo (Temporary)

For initial Linux port development, we could:
1. Create a minimal RepoBarCore that doesn't depend on Apollo
2. Focus on CLI tool first (uses REST API)
3. Add GraphQL support later once apollo-ios is fixed

## Proposed Build Structure

### Phase 1: CLI-Only Build

```bash
# Create Linux-specific CLI target that doesn't use GraphQL
swift build --target repobarcli-linux
```

This would require:
- Removing Apollo dependency from CLI
- Using only REST API
- Platform-agnostic code only

### Phase 2: Core Library for Linux

```bash
# Build core with patched dependencies
swift build --target RepoBarCore-linux
```

This would require:
- Patched apollo-ios with FoundationNetworking
- Platform abstractions for file I/O
- Linux-specific OAuth handling

### Phase 3: GUI Application

```bash
# Build full Linux application
swift build --target repobar-linux
```

This would require:
- System tray implementation (D-Bus)
- Menu system (Qt or GTK)
- Settings UI
- All of Phase 1 & 2

## Testing the Build

### Environment Check

```bash
# Check Swift version
swift --version
# Should show: Swift version 6.2.x

# Check platform
uname -s
# Should show: Linux

# Check architecture
uname -m
# Should show: x86_64 or aarch64

# Check available packages
swift package show-dependencies
```

### Running Tests

Once the build succeeds:

```bash
# Run all tests
swift test

# Run specific test
swift test --filter RepoBarCoreTests
```

## Development Workflow

### Recommended Approach

1. **Start with documentation** (current phase)
   - Document all platform dependencies
   - Plan abstraction layers
   - Create build guides

2. **Fix dependency issues**
   - Fork/patch apollo-ios for Linux
   - Test that RepoBarCore builds

3. **Build CLI tool first**
   - Validate core functionality works on Linux
   - Test GitHub API integration
   - Test authentication flow

4. **Add system tray support**
   - Implement D-Bus StatusNotifierItem
   - Get icon in system tray
   - Add basic menu

5. **Incrementally add features**
   - Rich menu items
   - Settings UI
   - Auto-start
   - Notifications

### Tools for Development

```bash
# Watch for changes and rebuild
find Sources -name "*.swift" | entr -r swift build

# Format code (if swiftformat available on Linux)
swiftformat Sources/

# Run specific target
swift run repobarcli-linux -- repos --mine
```

## Package.swift Changes Needed

### Current Package.swift Issues

1. Platform specification needs Linux:
   ```swift
   platforms: [
       .macOS(.v15),
       .iOS(.v26),
       // .linux  // Need to add this
   ],
   ```

2. Dependencies need conditional inclusion:
   ```swift
   dependencies: [
       // macOS-only
       .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
       .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.2.2"),
       
       // Linux-only (to be added)
       // .package(url: "https://github.com/.../swift-dbus", from: "1.0.0"),
   ],
   ```

3. Targets need platform-specific variants:
   ```swift
   .executableTarget(
       name: "repobar-linux",
       dependencies: [
           "RepoBarCore",
           // Linux-specific deps
       ]
   ),
   ```

### Proposed Package.swift Structure

See [linux-port.md](./linux-port.md) for detailed Package.swift changes.

## Known Limitations

### Cannot Do Yet
- ❌ Build complete application on Linux
- ❌ System tray integration
- ❌ Rich menu UI
- ❌ OAuth with browser integration
- ❌ Keychain-like secure storage

### Can Do (With Workarounds)
- ✅ Build core models and logic (after apollo-ios fix)
- ✅ GitHub REST API calls
- ✅ Local git operations
- ✅ CLI tool (after dependencies fixed)
- ✅ File I/O and settings storage

## Next Steps

1. **File issue with apollo-ios** about Linux support
   - Report missing FoundationNetworking imports
   - Provide patch or PR

2. **Create forked apollo-ios** with Linux fixes
   - Add required imports
   - Test on Linux
   - Use as temporary dependency

3. **Restructure Package.swift**
   - Add platform conditionals
   - Create Linux-specific targets
   - Remove macOS-only deps for Linux builds

4. **Implement platform abstraction layer**
   - Define protocols for system integration
   - Implement macOS version (existing code)
   - Implement Linux stubs

5. **Get minimal build working**
   - CLI tool first
   - Then core library
   - Then GUI components

## Resources

### Swift on Linux
- [Swift.org - Getting Started on Linux](https://www.swift.org/getting-started/#on-linux)
- [Swift Package Manager](https://github.com/apple/swift-package-manager)
- [Swift Forums - Linux Category](https://forums.swift.org/c/development/linux)

### Linux Desktop Integration
- [StatusNotifierItem Spec](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/)
- [DBusMenu Protocol](https://github.com/AyatanaIndicators/libdbusmenu)
- [XDG Desktop Entry Spec](https://specifications.freedesktop.org/desktop-entry-spec/latest/)

### Swift D-Bus Libraries
- [swift-dbus](https://github.com/PADL/swift-dbus) - D-Bus bindings for Swift
- [DBus.swift](https://github.com/piwigo/DBus.swift) - Another D-Bus library

### Qt/GTK with Swift
- [SwiftGtk](https://github.com/rhx/SwiftGtk) - GTK bindings
- [SwiftQt](https://github.com/DimaRU/SwiftQt) - Qt bindings (experimental)

## Contributing

If you're working on the Linux port, please:

1. Document any issues you encounter
2. Share workarounds and solutions
3. Test on multiple distributions
4. Report compatibility issues
5. Contribute platform-specific code

See [linux-port.md](./linux-port.md) for the full implementation plan.

## Questions?

For Linux-specific questions:
- Check existing GitHub issues tagged with `linux` or `kde`
- Ask in GitHub Discussions
- Review the implementation plan in `linux-port.md`
