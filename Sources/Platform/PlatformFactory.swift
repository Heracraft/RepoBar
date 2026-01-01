// Sources/Platform/PlatformFactory.swift
// Factory for creating platform-specific implementations

import Foundation

/// Factory for creating platform-specific instances
///
/// This factory provides the correct implementation for each platform,
/// abstracting away the conditional compilation logic.
public enum PlatformFactory {
    /// Creates a system tray instance for the current platform
    public static func createSystemTray() -> SystemTray {
        #if os(macOS)
        return MacOSSystemTray()
        #elseif os(Linux)
        return LinuxSystemTray()
        #else
        #error("Unsupported platform")
        #endif
    }

    /// Creates a menu instance for the current platform
    public static func createMenu(title: String = "") -> PlatformMenu {
        #if os(macOS)
        return MacOSPlatformMenu(title: title)
        #elseif os(Linux)
        return LinuxPlatformMenu()
        #else
        #error("Unsupported platform")
        #endif
    }

    /// Creates a menu item instance for the current platform
    public static func createMenuItem(title: String = "", action: (() -> Void)? = nil) -> PlatformMenuItem {
        #if os(macOS)
        return MacOSPlatformMenuItem(title: title, action: action)
        #elseif os(Linux)
        return LinuxPlatformMenuItem(title: title)
        #else
        #error("Unsupported platform")
        #endif
    }

    /// Creates a secure storage instance for the current platform
    public static func createSecureStorage() -> SecureStorage {
        #if os(macOS)
        return MacOSSecureStorage()
        #elseif os(Linux)
        return LinuxSecureStorage()
        #else
        #error("Unsupported platform")
        #endif
    }

    /// Creates a browser launcher instance for the current platform
    public static func createBrowserLauncher() -> BrowserLauncher {
        #if os(macOS)
        return MacOSBrowserLauncher()
        #elseif os(Linux)
        return LinuxBrowserLauncher()
        #else
        #error("Unsupported platform")
        #endif
    }
}
