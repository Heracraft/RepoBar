// Sources/Platform/Protocol/PlatformTypes.swift
// Platform-specific type aliases for cross-platform support

import Foundation

#if os(macOS)
import AppKit

/// Platform-specific image type (NSImage on macOS)
public typealias PlatformImage = NSImage

/// Platform-specific color type (NSColor on macOS)
public typealias PlatformColor = NSColor

#elseif os(Linux)

/// Platform-specific image type (placeholder on Linux)
public struct PlatformImage {
    // TODO: Implement Linux image representation
    public init() {}
}

/// Platform-specific color type (placeholder on Linux)
public struct PlatformColor {
    // TODO: Implement Linux color representation
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

#else
#error("Unsupported platform")
#endif
