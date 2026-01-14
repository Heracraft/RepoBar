# Linux/KDE Port Tracking Issue

This issue tracks the progress of porting RepoBar to Linux with KDE Plasma integration.

## 📋 Overview

RepoBar is currently a macOS-only application. This effort aims to bring RepoBar to Linux, with initial focus on KDE Plasma desktop environment.

## 📚 Documentation

- [Linux Port Plan](./linux-port.md) - Comprehensive implementation strategy
- [Building on Linux](./building-linux.md) - Build instructions and current limitations
- **[Future Work](./FUTURE_WORK.md) - Detailed next steps and implementation guide**

## 🎯 Goals

### Primary Goal
Create a Linux version of RepoBar that provides system tray integration with KDE Plasma, allowing users to monitor GitHub repositories from their desktop.

### Secondary Goals
- Maintain code sharing between macOS and Linux versions
- Use platform abstractions to minimize platform-specific code
- Provide similar functionality to macOS version
- Create distributable packages (AppImage, .deb, .rpm)

## 📊 Current Status

### ✅ Completed

- [x] Initial analysis of codebase and dependencies
- [x] Documentation of macOS-specific components
- [x] Linux port implementation plan created
- [x] Build guide for Linux created
- [x] Identified blocking issues
- [x] Created Linux build script
- [x] **Created platform abstraction layer** (2026-01-01)
  - [x] Defined SystemTray, PlatformMenu, PlatformMenuItem protocols
  - [x] Defined SecureStorage and BrowserLauncher protocols
  - [x] Created PlatformTypes with conditional type aliases
  - [x] Implemented macOS concrete types (wrappers around AppKit)
  - [x] Implemented Linux stub implementations
  - [x] Created PlatformFactory for cross-platform instantiation
- [x] **Added Platform target to Package.swift** (2026-01-01)
- [x] **Created repobar-linux executable placeholder** (2026-01-01)
- [x] **Verified Platform target builds on Linux** (2026-01-01)

### 🚧 In Progress

- [ ] Resolve apollo-ios Linux compatibility (blocks RepoBarCore on Linux)
- [ ] Implement actual Linux platform functionality (currently stubs)
- [ ] Update existing code to use Platform abstraction layer

### 📝 To Do

#### Phase 1: Foundation (Blocking Issues)
- [ ] **Fix apollo-ios dependency for Linux**
  - Issue: Missing `import FoundationNetworking` on Linux
  - Options:
    - [ ] Fork apollo-ios and add Linux support
    - [ ] Wait for upstream fix
    - [ ] Use alternative GraphQL client for Linux
  - **This is the primary blocker for RepoBarCore on Linux**
  - See [FUTURE_WORK.md](./FUTURE_WORK.md) Task 2 for detailed implementation guide

- [x] **Update Package.swift for cross-platform build** (2026-01-01)
  - [x] Added Platform target
  - [x] Created Linux-specific target (repobar-linux)
  - [ ] Add Linux platform support (deferred - causes macOS dependency issues)
  - [ ] Conditionalize macOS-only dependencies (future work)

#### Phase 2: Platform Abstraction
- [x] **Design platform abstraction protocols** (2026-01-01)
  - [x] SystemTray protocol
  - [x] PlatformMenu protocol
  - [x] PlatformMenuItem protocol
  - [x] PlatformImage/Color type aliases
  - [x] SecureStorage protocol
  - [x] BrowserLauncher protocol

- [x] **Implement macOS concrete types** (2026-01-01)
  - [x] Created wrappers around existing AppKit code
  - [x] No behavior changes to existing functionality
  - [ ] Migrate existing RepoBar code to use Platform abstractions (future work)
  - See [FUTURE_WORK.md](./FUTURE_WORK.md) Task 4 for migration guide

- [x] **Implement Linux stub types** (2026-01-01)
  - [x] LinuxSystemTray (placeholder with detailed implementation guide)
  - [x] LinuxPlatformMenu (placeholder with detailed implementation guide)
  - [x] LinuxSecureStorage (placeholder with detailed implementation guide)
  - [x] LinuxBrowserLauncher (basic xdg-open implementation)
  - [x] Enhanced all stubs with comprehensive TODO comments and implementation examples

#### Phase 3: Linux Implementation
- [ ] **System Tray Integration**
  - [ ] Research D-Bus StatusNotifierItem protocol
  - [ ] Choose implementation approach (Qt/GTK/pure D-Bus)
  - [ ] Implement LinuxSystemTray
  - [ ] Get icon to appear in KDE system tray
  - See [FUTURE_WORK.md](./FUTURE_WORK.md) Task 1.1 for detailed implementation guide

- [ ] **Menu System**
  - [ ] Implement DBusMenu protocol
  - [ ] Create LinuxPlatformMenu
  - [ ] Support text menu items initially
  - [ ] Test menu interaction
  - See [FUTURE_WORK.md](./FUTURE_WORK.md) Task 1.2 for detailed implementation guide

- [ ] **OAuth/Browser Integration**
  - [ ] Replace NSWorkspace.open with xdg-open
  - [ ] Test loopback server on Linux
  - [ ] Handle custom URL scheme registration
  - [ ] Test OAuth flow end-to-end

- [ ] **Secure Storage**
  - [ ] Research KWallet integration
  - [ ] Implement libsecret fallback
  - [ ] Create LinuxSecureStorage
  - [ ] Test token storage/retrieval
  - See [FUTURE_WORK.md](./FUTURE_WORK.md) Task 3 for detailed implementation guide

#### Phase 4: CLI Tool
- [ ] **Get repobarcli building on Linux**
  - [ ] Fix dependency issues
  - [ ] Test basic commands
  - [ ] Verify GitHub API integration
  - [ ] Test on multiple distributions

#### Phase 5: GUI Application
- [ ] **Choose GUI framework**
  - [ ] Evaluate Qt for KDE
  - [ ] Evaluate GTK as alternative
  - [ ] Consider web-based UI
  - [ ] Make decision and document

- [ ] **Implement Settings UI**
  - [ ] Basic settings window
  - [ ] Account management
  - [ ] General preferences
  - [ ] Repository management

- [ ] **Desktop Integration**
  - [ ] Create .desktop file
  - [ ] Install icon to system
  - [ ] Handle autostart
  - [ ] Integrate with KDE

#### Phase 6: Distribution & Packaging
- [x] **Build System** (2026-01-01)
  - [x] Create Linux-specific build scripts
  - [x] Created build-appimage.sh for universal Linux packages
  - [x] Created build-deb.sh for Debian/Ubuntu/KDE Neon
  - [x] Created build-rpm.sh for Fedora/openSUSE
  - [ ] Setup CI for Linux builds
  - [ ] Test on multiple distributions

- [ ] **Package Creation**
  - [ ] Create AppImage
  - [ ] Create .deb package (Debian/Ubuntu/KDE Neon)
  - [ ] Create .rpm package (Fedora/openSUSE)
  - [ ] Consider Flatpak
  - [ ] Consider Snap
  - See [FUTURE_WORK.md](./FUTURE_WORK.md) Task 5 for detailed packaging guide

#### Phase 7: Testing & Polish
- [ ] **Testing**
  - [ ] Test on KDE Neon
  - [ ] Test on Kubuntu
  - [ ] Test on Fedora KDE
  - [ ] Test on openSUSE
  - [ ] Document any distribution-specific issues

- [ ] **Documentation**
  - [ ] Update README with Linux instructions
  - [ ] Create installation guide
  - [ ] Document known limitations
  - [ ] Add screenshots

## 🚫 Blockers

### Critical Blockers

1. **apollo-ios Linux Support**
   - **Impact**: Cannot build RepoBarCore
   - **Status**: Reported to upstream (needs tracking)
   - **Workaround**: Fork and patch locally
   - **Resolution**: Waiting for upstream fix or maintaining fork

### Major Issues

2. **No System Tray Library**
   - **Impact**: Need to implement from scratch or wrap Qt/GTK
   - **Status**: Research needed
   - **Options**: Swift-Qt, SwiftGtk, or custom D-Bus implementation

3. **No Keychain Equivalent**
   - **Impact**: Need secure token storage
   - **Status**: Multiple options available (KWallet, libsecret)
   - **Resolution**: Implement platform abstraction

## 🔗 Dependencies

### Must Have for Linux
- Swift 6.2+
- Foundation
- FoundationNetworking (on Linux)
- D-Bus (system integration)

### Need Alternatives
- ~~Sparkle~~ → Custom update mechanism or AppImageUpdate
- ~~MenuBarExtraAccess~~ → D-Bus StatusNotifierItem
- ~~NSWorkspace~~ → xdg-open, D-Bus
- ~~Keychain~~ → KWallet or libsecret

### Cross-Platform (Already Compatible)
- swift-log ✅
- swift-algorithms ✅
- swift-markdown ✅
- Commander ✅
- Kingfisher ✅ (mostly)

## 📈 Milestones

### Milestone 1: Foundation Ready ✅ (Completed 2026-01-01)
**Goal**: Get basic codebase building on Linux

- [ ] apollo-ios fixed for Linux (still blocked)
- [x] Package.swift supports Linux (Platform target added)
- [ ] RepoBarCore builds successfully (blocked on apollo-ios)
- [x] Platform abstraction layer defined
- [x] Platform target builds on Linux
- [x] repobar-linux placeholder builds and runs

**Status**: Partially complete - Platform abstraction layer is done, but RepoBarCore still blocked on apollo-ios

### Milestone 2: CLI Functional
**Goal**: Command-line tool works on Linux

- [ ] repobarcli builds
- [ ] Authentication works
- [ ] GitHub API calls succeed
- [ ] Local git integration works

**ETA**: TBD (after Milestone 1)

### Milestone 3: System Tray MVP
**Goal**: Icon appears in KDE system tray with basic menu

- [ ] System tray icon visible
- [ ] Simple text menu works
- [ ] Basic repository list shows
- [ ] Can refresh data

**ETA**: TBD (after Milestone 2)

### Milestone 4: Feature Parity
**Goal**: Linux version has most macOS features

- [ ] Rich menu content
- [ ] Settings UI
- [ ] OAuth flow
- [ ] Notifications
- [ ] Auto-start

**ETA**: TBD (after Milestone 3)

### Milestone 5: Distribution Ready
**Goal**: Packages available for users to install

- [ ] AppImage created
- [ ] .deb package created
- [ ] Documentation complete
- [ ] Tested on multiple distros

**ETA**: TBD (after Milestone 4)

## 🤝 How to Help

### For Developers

1. **Fix apollo-ios for Linux**
   - Add `import FoundationNetworking` where needed
   - Submit PR to apollo-ios
   - Or maintain a fork

2. **Implement Platform Abstractions**
   - Define protocols for system integration
   - Implement Linux versions
   - Keep macOS working

3. **Test on Different Distributions**
   - Try building on various Linux distros
   - Report compatibility issues
   - Document workarounds

### For Users

1. **Provide Feedback**
   - What features are most important?
   - What KDE integrations would be useful?
   - Test early builds

2. **Documentation**
   - Improve Linux build instructions
   - Add screenshots
   - Write user guides

### 📖 Resources

### Documentation
- [docs/linux-port.md](./linux-port.md) - Full implementation plan
- [docs/building-linux.md](./building-linux.md) - Build guide and current status
- **[docs/FUTURE_WORK.md](./FUTURE_WORK.md) - Detailed next steps with implementation examples**

### External Resources
- [Swift on Linux](https://www.swift.org/download/#linux)
- [StatusNotifierItem Spec](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/)
- [DBusMenu Protocol](https://github.com/AyatanaIndicators/libdbusmenu)
- [apollo-ios](https://github.com/apollographql/apollo-ios)

### Related Projects
- [SwiftGtk](https://github.com/rhx/SwiftGtk) - GTK bindings for Swift
- [swift-dbus](https://github.com/PADL/swift-dbus) - D-Bus bindings

## 💬 Discussion

For discussions about the Linux port:
- Comment on this issue for general questions
- Open separate issues for specific bugs/features
- Use GitHub Discussions for design decisions

## 📝 Notes

- This is a large effort that will take time
- macOS version remains the primary focus
- Linux port should not compromise macOS functionality
- We aim for code sharing where possible
- Platform-specific code is acceptable when necessary

---

**Last Updated**: 2026-01-01
**Status**: 🟡 Planning & Research Phase
