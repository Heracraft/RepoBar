import AppKit
import MenuBarExtraAccess
import SwiftUI

@main
struct RepoBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        // Hidden lifecycle keeper so Settings window can appear even without a main window (mirrors CodexBar/Trimmy)
        WindowGroup("RepoBarLifecycleKeepalive") {
            HiddenWindowView()
        }
        .defaultSize(width: 1, height: 1)
        .windowStyle(.hiddenTitleBar)
    }
}

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ensureSingleInstance() else {
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.accessory)
        self.statusBarController = StatusBarController(appState: self.appState)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

extension AppDelegate {
    /// Prevent multiple instances when LS UI flag is unavailable under SwiftPM.
    private func ensureSingleInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return true }
        let others = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID && !$0.isEqual(NSRunningApplication.current)
        }
        return others.isEmpty
    }
}

// MARK: - Hidden Window View

struct HiddenWindowView: View {
    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
    }
}

// MARK: - AppState container

@MainActor
final class AppState: ObservableObject {
    @Published var session = Session()
    let auth = OAuthCoordinator()
    let github = GitHubClient()
    let refreshScheduler = RefreshScheduler()
    private let settingsStore = SettingsStore()

    init() {
        self.session.settings = self.settingsStore.load()
        Task {
            await self.github.setTokenProvider { @Sendable [weak self] () async throws -> OAuthTokens? in
                try? await self?.auth.refreshIfNeeded()
            }
        }
        self.refreshScheduler.configure(interval: self.session.settings.refreshInterval.seconds) { [weak self] in
            Task { await self?.refresh() }
        }
    }

    func refresh() async {
        do {
            if self.auth.loadTokens() == nil {
                await MainActor.run {
                    self.session.repositories = []
                    self.session.lastError = nil
                }
                return
            }
            let repoNames = self.session.settings.pinnedRepositories
            let repos: [Repository] = if !repoNames.isEmpty {
                try await self.fetchPinned(repoNames: repoNames)
            } else {
                try await self.github.defaultRepositories(
                    limit: self.session.settings.repoDisplayLimit,
                    for: self.currentUserNameOrEmpty())
            }
            let trimmed = Array(repos.prefix(self.session.settings.repoDisplayLimit))
            await MainActor.run {
                self.session.repositories = trimmed.map { repo in
                    if let idx = session.settings.pinnedRepositories.firstIndex(of: repo.fullName) {
                        return repo.withOrder(idx)
                    }
                    return repo
                }
                self.session.rateLimitReset = nil
                self.session.lastError = nil
            }
            self.session.rateLimitReset = await self.github.rateLimitReset()
            self.session.lastError = await self.github.rateLimitMessage()
        } catch {
            await MainActor.run { self.session.lastError = error.userFacingMessage }
        }
    }

    func addPinned(_ fullName: String) async {
        guard !self.session.settings.pinnedRepositories.contains(fullName) else { return }
        self.session.settings.pinnedRepositories.append(fullName)
        self.settingsStore.save(self.session.settings)
        await self.refresh()
    }

    func removePinned(_ fullName: String) async {
        self.session.settings.pinnedRepositories.removeAll { $0 == fullName }
        self.settingsStore.save(self.session.settings)
        await self.refresh()
    }

    func persistSettings() {
        self.settingsStore.save(self.session.settings)
    }

    private func currentUserNameOrEmpty() -> String {
        if case let .loggedIn(user) = session.account { return user.username }
        return ""
    }

    private func fetchPinned(repoNames: [String]) async throws -> [Repository] {
        try await withThrowingTaskGroup(of: (Int, Repository).self) { group in
            for (idx, name) in repoNames.enumerated() {
                let parts = name.split(separator: "/", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }
                group.addTask {
                    let repo = try await self.github.fullRepository(owner: parts[0], name: parts[1])
                    return (idx, repo.withOrder(idx))
                }
            }
            var items: [(Int, Repository)] = []
            for try await pair in group {
                items.append(pair)
            }
            return items.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}

final class Session: ObservableObject {
    @Published var account: AccountState = .loggedOut
    @Published var repositories: [Repository] = []
    @Published var settings = UserSettings()
    @Published var rateLimitReset: Date?
    @Published var lastError: String?
}

enum AccountState: Equatable {
    case loggedOut
    case loggingIn
    case loggedIn(UserIdentity)
}

struct UserIdentity: Equatable {
    let username: String
    let host: URL
}

struct UserSettings: Equatable, Codable {
    var showContributionHeader = true
    var repoDisplayLimit: Int = 5
    var refreshInterval: RefreshInterval = .fiveMinutes
    var launchAtLogin = false
    var showHeatmap = true
    var githubHost: URL = .init(string: "https://github.com")!
    var enterpriseHost: URL?
    var loopbackPort: Int = 53682
    var pinnedRepositories: [String] = [] // owner/name
}

enum RefreshInterval: CaseIterable, Equatable, Codable {
    case oneMinute, twoMinutes, fiveMinutes, fifteenMinutes

    var seconds: TimeInterval {
        switch self {
        case .oneMinute: 60
        case .twoMinutes: 120
        case .fiveMinutes: 300
        case .fifteenMinutes: 900
        }
    }
}
