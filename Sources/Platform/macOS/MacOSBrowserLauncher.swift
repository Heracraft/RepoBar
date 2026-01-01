// Sources/Platform/macOS/MacOSBrowserLauncher.swift
// macOS implementation of browser launching using NSWorkspace

#if os(macOS)

import AppKit
import Foundation

/// macOS browser launcher using NSWorkspace
///
/// Uses AppKit's NSWorkspace to launch URLs in the system's default browser.
public final class MacOSBrowserLauncher: BrowserLauncher {
    public init() {}

    public func openURL(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    public func openURLAsync(_ url: URL) async -> Bool {
        await MainActor.run {
            NSWorkspace.shared.open(url)
        }
    }
}

#endif
