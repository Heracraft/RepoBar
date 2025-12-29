import AppKit
import Observation
import RepoBarCore
import SwiftUI

@MainActor
final class StatusBarMenuManager: NSObject, NSMenuDelegate {
    private let appState: AppState
    private var mainMenu: NSMenu?
    private lazy var menuBuilder = StatusBarMenuBuilder(appState: self.appState, target: self)
    private var recentListMenuContexts: [ObjectIdentifier: RepoRecentMenuContext] = [:]

    private let recentListLimit = 20
    private let recentListCacheTTL: TimeInterval = 90
    private let recentIssuesCache = RecentListCache<RepoIssueSummary>()
    private let recentPullRequestsCache = RecentListCache<RepoPullRequestSummary>()

    init(appState: AppState) {
        self.appState = appState
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.menuFiltersChanged),
            name: .menuFiltersDidChange,
            object: nil
        )
    }

    func attachMainMenu(to statusItem: NSStatusItem) {
        let menu = self.mainMenu ?? self.menuBuilder.makeMainMenu()
        self.mainMenu = menu
        statusItem.menu = menu
    }

    // MARK: - Menu actions

    @objc func refreshNow() {
        self.appState.requestRefresh(cancelInFlight: true)
    }

    @objc func openPreferences() {
        SettingsOpener.shared.open()
    }

    @objc func openAbout() {
        AppActions.openAbout()
    }

    @objc func checkForUpdates() {
        SparkleController.shared.checkForUpdates()
    }

    @objc func menuFiltersChanged() {
        guard let menu = self.mainMenu else { return }
        self.recentListMenuContexts.removeAll(keepingCapacity: true)
        self.appState.persistSettings()
        self.menuBuilder.populateMainMenu(menu)
        self.menuBuilder.refreshMenuViewHeights(in: menu)
        menu.update()
    }

    @objc func logOut() {
        Task { @MainActor in
            await self.appState.auth.logout()
            self.appState.session.account = .loggedOut
            self.appState.session.repositories = []
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    @objc func signIn() {
        Task { await self.appState.quickLogin() }
    }

    @objc func openRepo(_ sender: NSMenuItem) {
        guard let fullName = self.repoFullName(from: sender),
              let url = self.repoURL(for: fullName) else { return }
        self.open(url: url)
    }

    func openRepoFromMenu(fullName: String) {
        guard let url = self.repoURL(for: fullName) else { return }
        self.open(url: url)
    }

    @objc func openIssues(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "issues")
    }

    @objc func openPulls(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "pulls")
    }

    @objc func openActions(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "actions")
    }

    @objc func openReleases(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "releases")
    }

    @objc func openLatestRelease(_ sender: NSMenuItem) {
        guard let repo = self.repoModel(from: sender),
              let url = repo.source.latestRelease?.url else { return }
        self.open(url: url)
    }

    @objc func openActivity(_ sender: NSMenuItem) {
        guard let repo = self.repoModel(from: sender),
              let url = repo.activityURL else { return }
        self.open(url: url)
    }

    @objc func openActivityEvent(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        self.open(url: url)
    }

    @objc func openURLItem(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        self.open(url: url)
    }

    @objc func openLocalFinder(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        self.open(url: url)
    }

    @objc func openLocalTerminal(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        let preferred = self.appState.session.settings.localProjects.preferredTerminal
        let terminal = TerminalApp.resolve(preferred)
        terminal.open(at: url)
    }

    @objc func copyRepoName(_ sender: NSMenuItem) {
        guard let fullName = self.repoFullName(from: sender) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(fullName, forType: .string)
    }

    @objc func copyRepoURL(_ sender: NSMenuItem) {
        guard let fullName = self.repoFullName(from: sender),
              let url = self.repoURL(for: fullName) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(url.absoluteString, forType: .string)
    }

    @objc func pinRepo(_ sender: NSMenuItem) {
        guard let fullName = self.repoFullName(from: sender) else { return }
        Task { await self.appState.addPinned(fullName) }
    }

    @objc func unpinRepo(_ sender: NSMenuItem) {
        guard let fullName = self.repoFullName(from: sender) else { return }
        Task { await self.appState.removePinned(fullName) }
    }

    @objc func hideRepo(_ sender: NSMenuItem) {
        guard let fullName = self.repoFullName(from: sender) else { return }
        Task { await self.appState.hide(fullName) }
    }

    @objc func moveRepoUp(_ sender: NSMenuItem) {
        self.moveRepo(sender: sender, direction: -1)
    }

    @objc func moveRepoDown(_ sender: NSMenuItem) {
        self.moveRepo(sender: sender, direction: 1)
    }

    private func moveRepo(sender: NSMenuItem, direction: Int) {
        guard let fullName = self.repoFullName(from: sender) else { return }
        var pins = self.appState.session.settings.repoList.pinnedRepositories
        guard let currentIndex = pins.firstIndex(of: fullName) else { return }
        let maxIndex = max(pins.count - 1, 0)
        let target = max(0, min(maxIndex, currentIndex + direction))
        guard target != currentIndex else { return }
        pins.move(fromOffsets: IndexSet(integer: currentIndex), toOffset: target > currentIndex ? target + 1 : target)
        self.appState.session.settings.repoList.pinnedRepositories = pins
        self.appState.persistSettings()
        self.appState.requestRefresh(cancelInFlight: true)
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.appearance = NSApp.effectiveAppearance
        if let context = self.recentListMenuContexts[ObjectIdentifier(menu)] {
            Task { @MainActor [weak self] in
                await self?.refreshRecentListMenu(menu: menu, context: context)
            }
            return
        }
        if menu === self.mainMenu {
            self.recentListMenuContexts.removeAll(keepingCapacity: true)
            self.appState.refreshIfNeededForMenu()
            self.menuBuilder.populateMainMenu(menu)
            self.menuBuilder.refreshMenuViewHeights(in: menu)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.menuBuilder.refreshMenuViewHeights(in: menu)
                menu.update()
                self.menuBuilder.clearHighlights(in: menu)
            }
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu === self.mainMenu {
            self.menuBuilder.clearHighlights(in: menu)
        }
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        for menuItem in menu.items {
            guard let view = menuItem.view as? MenuItemHighlighting else { continue }
            let highlighted = menuItem == item && menuItem.isEnabled
            view.setHighlighted(highlighted)
        }
    }

    // MARK: - Main menu

    private func refreshRecentListMenu(menu: NSMenu, context: RepoRecentMenuContext) async {
        guard case .loggedIn = self.appState.session.account else {
            let header = RecentMenuHeader(title: "Sign in to view", action: nil, fullName: context.fullName, systemImage: nil)
            self.populateRecentListMenu(menu, header: header, rows: .signedOut)
            menu.update()
            return
        }
        guard let (owner, name) = self.ownerAndName(from: context.fullName) else {
            let header = RecentMenuHeader(
                title: "Open on GitHub",
                action: #selector(self.openRepo),
                fullName: context.fullName,
                systemImage: "folder"
            )
            self.populateRecentListMenu(menu, header: header, rows: .message("Invalid repository name"))
            menu.update()
            return
        }

        let now = Date()
        switch context.kind {
        case .issues:
            let header = RecentMenuHeader(
                title: "Open Issues",
                action: #selector(self.openIssues),
                fullName: context.fullName,
                systemImage: "exclamationmark.circle"
            )
            let cached = self.recentIssuesCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            if let cached {
                self.populateRecentListMenu(menu, header: header, rows: .issues(cached))
            } else {
                self.populateRecentListMenu(menu, header: header, rows: .loading)
            }
            menu.update()

            guard self.recentIssuesCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentIssuesCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentIssues(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentIssuesCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentIssuesCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, rows: .issues(items))
            } catch {
                self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
            }
            menu.update()
        case .pullRequests:
            let header = RecentMenuHeader(
                title: "Open Pull Requests",
                action: #selector(self.openPulls),
                fullName: context.fullName,
                systemImage: "arrow.triangle.branch"
            )
            let cached = self.recentPullRequestsCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            if let cached {
                self.populateRecentListMenu(menu, header: header, rows: .pullRequests(cached))
            } else {
                self.populateRecentListMenu(menu, header: header, rows: .loading)
            }
            menu.update()

            guard self.recentPullRequestsCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentPullRequestsCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentPullRequests(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentPullRequestsCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentPullRequestsCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, rows: .pullRequests(items))
            } catch {
                self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
            }
            menu.update()
        }
    }

    private enum RecentMenuRows {
        case signedOut
        case loading
        case message(String)
        case issues([RepoIssueSummary])
        case pullRequests([RepoPullRequestSummary])
    }

    private struct RecentMenuHeader {
        let title: String
        let action: Selector?
        let fullName: String
        let systemImage: String?
    }

    private func populateRecentListMenu(_ menu: NSMenu, header: RecentMenuHeader, rows: RecentMenuRows) {
        menu.removeAllItems()

        let open = NSMenuItem(title: header.title, action: header.action, keyEquivalent: "")
	        open.target = self
	        open.representedObject = header.fullName
	        if let systemImage = header.systemImage,
	           let image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil) {
	            image.size = NSSize(width: 14, height: 14)
	            image.isTemplate = true
	            open.image = image
	        }
        open.isEnabled = header.action != nil
        menu.addItem(open)

        menu.addItem(.separator())

        switch rows {
        case .signedOut:
            let item = NSMenuItem(title: "Sign in to load items", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        case .loading:
            let item = NSMenuItem(title: "Loading…", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        case let .message(text):
            let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        case let .issues(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No open issues", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for issue in items.prefix(self.recentListLimit) {
                self.addIssueMenuItem(issue, to: menu)
            }
            self.menuBuilder.refreshMenuViewHeights(in: menu)
        case let .pullRequests(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No open pull requests", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for pr in items.prefix(self.recentListLimit) {
                self.addPullRequestMenuItem(pr, to: menu)
            }
            self.menuBuilder.refreshMenuViewHeights(in: menu)
        }
    }

    private func addIssueMenuItem(_ issue: RepoIssueSummary, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            IssueMenuItemView(issue: issue) { [weak self] in
                self?.open(url: issue.url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = self.recentItemTooltip(title: issue.title, author: issue.authorLogin, updatedAt: issue.updatedAt)
        menu.addItem(item)
    }

    private func addPullRequestMenuItem(_ pullRequest: RepoPullRequestSummary, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            PullRequestMenuItemView(pullRequest: pullRequest) { [weak self] in
                self?.open(url: pullRequest.url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = self.recentItemTooltip(
            title: pullRequest.title,
            author: pullRequest.authorLogin,
            updatedAt: pullRequest.updatedAt
        )
        menu.addItem(item)
    }

    private func recentItemTooltip(title: String, author: String?, updatedAt: Date) -> String {
        var parts: [String] = []
        if let author, !author.isEmpty {
            parts.append("@\(author)")
        }
        parts.append("Updated \(RelativeFormatter.string(from: updatedAt, relativeTo: Date()))")
        parts.append(title)
        return parts.joined(separator: "\n")
    }

    private func repoModel(from sender: NSMenuItem) -> RepositoryDisplayModel? {
        guard let fullName = self.repoFullName(from: sender) else { return nil }
        guard let repo = self.appState.session.repositories.first(where: { $0.fullName == fullName }) else { return nil }
        let local = self.appState.session.localRepoIndex.status(forFullName: fullName)
        return RepositoryDisplayModel(repo: repo, localStatus: local)
    }

    private func repoFullName(from sender: NSMenuItem) -> String? {
        sender.representedObject as? String
    }

    private func repoURL(for fullName: String) -> URL? {
        let parts = fullName.split(separator: "/", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        var url = self.appState.session.settings.githubHost
        url.appendPathComponent(String(parts[0]))
        url.appendPathComponent(String(parts[1]))
        return url
    }

    private func ownerAndName(from fullName: String) -> (String, String)? {
        let parts = fullName.split(separator: "/", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }

    private func openRepoPath(sender: NSMenuItem, path: String) {
        guard let fullName = self.repoFullName(from: sender),
              var url = self.repoURL(for: fullName) else { return }
        url.appendPathComponent(path)
        self.open(url: url)
    }

    func open(url: URL) {
        NSWorkspace.shared.open(url)
    }

    @objc func menuItemNoOp(_: NSMenuItem) {}

    func registerRecentListMenu(_ menu: NSMenu, context: RepoRecentMenuContext) {
        self.recentListMenuContexts[ObjectIdentifier(menu)] = context
    }
}

private final class RecentListCache<Item: Sendable> {
    struct Entry { var fetchedAt: Date
        var items: [Item]
    }

    private var entries: [String: Entry] = [:]
    private var inflight: [String: Task<[Item], Error>] = [:]

    func cached(for key: String, now: Date, maxAge: TimeInterval) -> [Item]? {
        guard let entry = entries[key] else { return nil }
        guard now.timeIntervalSince(entry.fetchedAt) <= maxAge else { return nil }
        return entry.items
    }

    func needsRefresh(for key: String, now: Date, maxAge: TimeInterval) -> Bool {
        guard let entry = entries[key] else { return true }
        return now.timeIntervalSince(entry.fetchedAt) > maxAge
    }

    func task(for key: String, factory: @escaping @Sendable () async throws -> [Item]) -> Task<[Item], Error> {
        if let existing = inflight[key] { return existing }
        let task = Task { try await factory() }
        self.inflight[key] = task
        return task
    }

    func clearInflight(for key: String) {
        self.inflight[key] = nil
    }

    func store(_ items: [Item], for key: String, fetchedAt: Date) {
        self.entries[key] = Entry(fetchedAt: fetchedAt, items: items)
    }
}
