// Sources/Platform/Linux/LinuxBrowserLauncher.swift
// Linux implementation of browser launching using xdg-open

#if os(Linux)

import Foundation

/// Linux browser launcher using xdg-open
///
/// Uses xdg-open to launch URLs in the system's default browser.
/// This works across most Linux desktop environments including KDE.
public final class LinuxBrowserLauncher: BrowserLauncher {
    public init() {}

    public func openURL(_ url: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
        process.arguments = [url.absoluteString]

        do {
            try process.run()
            return true
        } catch {
            print("Failed to launch browser: \(error)")
            return false
        }
    }

    public func openURLAsync(_ url: URL) async -> Bool {
        openURL(url)
    }
}

#endif
