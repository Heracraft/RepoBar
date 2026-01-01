// Sources/repobar-linux/main.swift
// Linux application entry point for RepoBar

#if os(Linux)

import Foundation
// import Platform - Will be enabled once Platform target is available

print("RepoBar for Linux - Work in Progress")
print("")
print("This is a placeholder for the Linux version of RepoBar.")
print("The Linux port is currently under development.")
print("")
print("Current status:")
print("  ✓ Platform abstraction layer created")
print("  ✓ Linux stub implementations created")
print("  ⧗ System tray integration (StatusNotifierItem) - TODO")
print("  ⧗ Menu system (DBusMenu) - TODO")
print("  ⧗ Secure storage (KWallet/libsecret) - TODO")
print("  ⧗ OAuth browser integration - TODO")
print("")
print("For more information, see:")
print("  - docs/linux-port.md")
print("  - docs/building-linux.md")
print("  - docs/LINUX_PORT_TRACKING.md")
print("")
print("To use RepoBar functionality on Linux right now, try the CLI tool:")
print("  swift build --product repobarcli")
print("  .build/debug/repobarcli --help")

#else
#error("repobar-linux target should only be built on Linux")
#endif
