// Sources/Platform/Protocol/BrowserLauncher.swift
// Platform abstraction for launching URLs in system browser

import Foundation

/// Protocol for opening URLs in the system's default browser
///
/// On macOS, this uses NSWorkspace.
/// On Linux, this uses xdg-open via D-Bus or direct process launch.
public protocol BrowserLauncher {
    /// Opens a URL in the system's default browser
    /// - Parameter url: The URL to open
    /// - Returns: true if the URL was successfully opened, false otherwise
    func openURL(_ url: URL) -> Bool

    /// Opens a URL in the system's default browser asynchronously
    /// - Parameter url: The URL to open
    func openURLAsync(_ url: URL) async -> Bool
}
