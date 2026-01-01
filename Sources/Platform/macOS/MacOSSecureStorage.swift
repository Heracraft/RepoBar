// Sources/Platform/macOS/MacOSSecureStorage.swift
// macOS implementation of secure storage using Keychain

#if os(macOS)

import Foundation
import Security

/// macOS secure storage implementation using Keychain Services
///
/// Wraps macOS Keychain to provide a cross-platform interface for
/// secure credential storage.
public final class MacOSSecureStorage: SecureStorage {
    public init() {}

    public func store(_ value: String, forKey key: String, service: String?) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStorageError.unknown("Failed to encode value as UTF-8")
        }

        let serviceName = service ?? "com.steipete.repobar"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        // Try to delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw mapKeychainError(status)
        }
    }

    public func retrieve(forKey key: String, service: String?) throws -> String? {
        let serviceName = service ?? "com.steipete.repobar"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw mapKeychainError(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.unknown("Failed to decode stored data")
        }

        return string
    }

    public func delete(forKey key: String, service: String?) throws {
        let serviceName = service ?? "com.steipete.repobar"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw mapKeychainError(status)
        }
    }

    private func mapKeychainError(_ status: OSStatus) -> SecureStorageError {
        switch status {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecAuthFailed:
            return .accessDenied
        default:
            return .unknown("Keychain error: \(status)")
        }
    }
}

#endif
