# Linux/KDE Port: Getting Started Guide

Quick reference for starting work on the Linux port of RepoBar.

## 🎯 Quick Start

1. **Read the documentation** (in order):
   - [Building on Linux](./building-linux.md) - Current status and limitations
   - [Linux Port Plan](./linux-port.md) - Complete implementation strategy
   - [Platform Abstraction Examples](./platform-abstraction-examples.md) - Code patterns
   - [Progress Tracking](./LINUX_PORT_TRACKING.md) - Task list and milestones

2. **Understand the blocker**:
   - apollo-ios doesn't support Linux (missing FoundationNetworking imports)
   - This prevents RepoBarCore from building
   - Must be resolved before any implementation work

3. **Choose how to contribute**:
   - Fix apollo-ios upstream
   - Create/maintain forked apollo-ios
   - Implement platform abstractions
   - Test on different distributions
   - Write documentation

## 🔴 Critical Blocker

**Issue**: apollo-ios library missing Linux support

**Impact**: Cannot build RepoBarCore, which blocks all development

**Symptoms**:
```
error: cannot find type 'URLRequest' in scope
error: 'HTTPURLResponse' is unavailable: This type has moved to the FoundationNetworking module
error: 'AsyncBytes' is not a member type of type 'Foundation.URLSession'
```

**Root cause**: Apollo files don't include `import FoundationNetworking` on Linux

**Solutions**:
1. **Fork apollo-ios** (quick but maintenance burden)
   - Clone https://github.com/apollographql/apollo-ios
   - Add conditional imports to affected files:
     ```swift
     #if canImport(FoundationNetworking)
     import FoundationNetworking
     #endif
     ```
   - Update Package.swift to use fork
   - Test RepoBarCore builds

2. **Submit PR to apollo-ios** (ideal but slower)
   - Same changes as fork
   - Submit to upstream
   - Wait for review/merge
   - Update to new version

3. **Use alternative GraphQL client** (nuclear option)
   - Replace apollo-ios entirely
   - Significant refactoring required
   - Not recommended

## 📋 Implementation Order

### Phase 1: Foundation (Dependencies)
**Goal**: Get code building on Linux

Tasks:
- [ ] Fix apollo-ios for Linux (blocker)
- [ ] Verify RepoBarCore builds
- [ ] Verify repobarcli builds
- [ ] Run existing tests on Linux

**Ready when**: `swift build` succeeds

### Phase 2: Abstractions (Architecture)
**Goal**: Isolate platform-specific code

Tasks:
- [ ] Create Platform module
- [ ] Define protocols (SystemTray, Menu, etc.)
- [ ] Wrap existing macOS code
- [ ] Create Linux stubs

**Ready when**: macOS app still works with new abstractions

### Phase 3: CLI (Validation)
**Goal**: Validate core functionality

Tasks:
- [ ] Build repobarcli on Linux
- [ ] Test authentication flow
- [ ] Test GitHub API calls
- [ ] Test local git operations

**Ready when**: CLI has feature parity on Linux

### Phase 4: System Tray (Basic GUI)
**Goal**: Icon in system tray

Tasks:
- [ ] Choose implementation (D-Bus/Qt/GTK)
- [ ] Implement StatusNotifierItem protocol
- [ ] Display icon in KDE tray
- [ ] Add basic text menu

**Ready when**: Icon appears and menu opens

### Phase 5: Features (Parity)
**Goal**: Similar functionality to macOS

Tasks:
- [ ] Implement DBusMenu for rich menus
- [ ] Create settings UI
- [ ] Add notifications
- [ ] Implement auto-start
- [ ] Add OAuth flow

**Ready when**: Core features work

### Phase 6: Distribution (Release)
**Goal**: Users can install

Tasks:
- [ ] Create packages (AppImage, .deb, .rpm)
- [ ] Test on multiple distros
- [ ] Write installation docs
- [ ] Setup auto-update mechanism

**Ready when**: Packages install and work

## 🛠️ Development Setup

### Requirements
- Linux distribution (KDE Neon, Kubuntu, Fedora KDE)
- Swift 6.2+ ([download](https://swift.org/download))
- Development tools: `build-essential`, `clang`, `libsqlite3-dev`
- Optional: D-Bus tools, Qt dev libs

### Get Started
```bash
# Clone repository
git clone https://github.com/Heracraft/RepoBar.git
cd RepoBar

# Check Swift version
swift --version  # Should be 6.2+

# Try building (will fail until apollo-ios is fixed)
./Scripts/build-linux.sh

# Read the error messages - they're helpful!
```

### Current Build Status
```bash
# These currently FAIL:
swift build --target RepoBarCore    # ❌ apollo-ios issue
swift build --target repobarcli     # ❌ depends on RepoBarCore
swift build                         # ❌ macOS-only targets

# After fixing apollo-ios:
swift build --target RepoBarCore    # ✅ should work
swift build --target repobarcli     # ✅ should work
```

## 📖 Documentation Index

| Document | Purpose | Read When |
|----------|---------|-----------|
| [building-linux.md](./building-linux.md) | Current status, issues, workarounds | Starting out, troubleshooting |
| [linux-port.md](./linux-port.md) | Complete implementation plan | Planning work, understanding scope |
| [platform-abstraction-examples.md](./platform-abstraction-examples.md) | Code examples and patterns | Implementing abstractions |
| [LINUX_PORT_TRACKING.md](./LINUX_PORT_TRACKING.md) | Task list and progress | Tracking work, contributing |

## 🤝 How to Contribute

### Option 1: Fix apollo-ios
**Best first contribution!**

1. Fork apollo-ios
2. Add Linux support (FoundationNetworking imports)
3. Test with RepoBar
4. Submit PR to apollo-ios upstream
5. Share fork with RepoBar project

### Option 2: Implement Abstractions
**After apollo-ios is fixed**

1. Create Platform module structure
2. Define protocols from examples
3. Implement macOS wrappers
4. Add Linux stubs
5. Test that macOS still works

### Option 3: Linux Implementation
**After abstractions exist**

1. Choose GUI approach (D-Bus/Qt/GTK)
2. Implement SystemTray for Linux
3. Implement Menu system for Linux
4. Test on KDE Plasma
5. Document integration points

### Option 4: Testing & Docs
**Always helpful!**

1. Test on different distributions
2. Document distribution-specific issues
3. Improve build instructions
4. Add screenshots
5. Write user guides

## 🔗 Useful Resources

### Swift on Linux
- [Swift.org Downloads](https://swift.org/download)
- [Swift Package Manager](https://github.com/apple/swift-package-manager)
- [Swift Forums - Linux](https://forums.swift.org/c/development/linux)

### Linux Desktop Integration
- [StatusNotifierItem Spec](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/)
- [DBusMenu](https://github.com/AyatanaIndicators/libdbusmenu)
- [XDG Desktop Entry](https://specifications.freedesktop.org/desktop-entry-spec/latest/)

### Libraries & Tools
- [swift-dbus](https://github.com/PADL/swift-dbus) - D-Bus bindings
- [SwiftGtk](https://github.com/rhx/SwiftGtk) - GTK bindings
- [apollo-ios](https://github.com/apollographql/apollo-ios) - GraphQL client (needs Linux support)

## 💡 Tips

### Building
- Use `./Scripts/build-linux.sh` for helpful diagnostics
- Read error messages carefully - they explain issues
- Start with RepoBarCore, then CLI, then GUI

### Testing
- Test on multiple Linux distributions
- KDE Neon is recommended (latest KDE)
- Document any distribution-specific issues

### Contributing
- Small PRs are easier to review
- Focus on one thing at a time
- Write tests when possible
- Update documentation

### Communication
- Comment on GitHub issues
- Ask questions in Discussions
- Share progress and blockers
- Help others get started

## ❓ FAQ

**Q: Can I start implementing Linux features now?**  
A: Not yet - apollo-ios blocker must be resolved first.

**Q: Which Linux distro should I use?**  
A: KDE Neon or Kubuntu for best KDE integration.

**Q: Do I need to know Swift?**  
A: Yes, RepoBar is written in Swift. But you can help with docs/testing!

**Q: Will this affect macOS version?**  
A: No, we'll use abstractions to keep macOS working perfectly.

**Q: How long will this take?**  
A: Unknown - depends on apollo-ios fix and contributor availability.

**Q: Can I help if I'm not a developer?**  
A: Yes! Testing, documentation, and bug reports are very helpful.

## 📞 Contact

- **Issues**: [GitHub Issues](https://github.com/Heracraft/RepoBar/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Heracraft/RepoBar/discussions)
- **Progress**: See [LINUX_PORT_TRACKING.md](./LINUX_PORT_TRACKING.md)

---

**Ready to start?** Read [building-linux.md](./building-linux.md) next!
