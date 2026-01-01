// Sources/Platform/Protocol/SecureStorage.swift
// Platform abstraction for secure credential storage

import Foundation

/// Protocol for secure storage of sensitive data like tokens
///
/// On macOS, this uses Keychain Services.
/// On Linux, this can use KWallet (KDE) or libsecret (GNOME/others).
public protocol SecureStorage {
    /// Stores a string value securely
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: The key to identify the stored value
    ///   - service: The service name (optional, for namespacing)
    /// - Throws: Storage errors
    func store(_ value: String, forKey key: String, service: String?) throws

    /// Retrieves a securely stored string value
    /// - Parameters:
    ///   - key: The key identifying the value
    ///   - service: The service name (optional, for namespacing)
    /// - Returns: The stored value, or nil if not found
    /// - Throws: Storage errors
    func retrieve(forKey key: String, service: String?) throws -> String?

    /// Deletes a securely stored value
    /// - Parameters:
    ///   - key: The key identifying the value to delete
    ///   - service: The service name (optional, for namespacing)
    /// - Throws: Storage errors
    func delete(forKey key: String, service: String?) throws
}

/// Errors that can occur during secure storage operations
public enum SecureStorageError: Error {
    case itemNotFound
    case duplicateItem
    case storageUnavailable
    case accessDenied
    case unknown(String)
}
