import AppKit
import Foundation
import OSLog
import RepoBarCore

/// Handles GitHub App OAuth using browser + loopback, PKCE, and refresh tokens.
@MainActor
final class OAuthCoordinator {
    private let tokenStore = TokenStore()
    private let tokenRefresher = OAuthTokenRefresher()
    private let logger = Logger(subsystem: "com.steipete.repobar", category: "oauth")
    private let signposter = OSSignposter(subsystem: "com.steipete.repobar", category: "oauth")
    private var lastHost: URL = .init(string: "https://github.com")!

    func login(clientID: String, clientSecret: String, host: URL, loopbackPort: Int) async throws {
        let normalizedHost = try OAuthLoginFlow.normalizeHost(host)
        self.lastHost = normalizedHost
        let flow = OAuthLoginFlow(tokenStore: self.tokenStore) { url in
            NSWorkspace.shared.open(url)
        }
        _ = try await flow.login(
            clientID: clientID,
            clientSecret: clientSecret,
            host: normalizedHost,
            loopbackPort: loopbackPort
        )
        await DiagnosticsLogger.shared.message("Login succeeded; tokens stored.")
    }

    func logout() async {
        self.tokenStore.clear()
    }

    func loadTokens() -> OAuthTokens? {
        try? self.tokenStore.load()
    }

    func refreshIfNeeded() async throws -> OAuthTokens? {
        let signpost = self.signposter.beginInterval("refreshIfNeeded")
        defer { self.signposter.endInterval("refreshIfNeeded", signpost) }
        try await self.tokenRefresher.refreshIfNeeded(host: self.lastHost)
    }

    // MARK: - Installation token

    // Installation flow removed: this app now uses user OAuth only.

    // PEM resolution removed; GitHub App installation tokens are not used.
}
