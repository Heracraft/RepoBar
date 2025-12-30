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
    private weak var menuResizeWindow: NSWindow?
    private var lastMainMenuWidth: CGFloat?

    private let recentListLimit = 20
    private let recentListCacheTTL: TimeInterval = 90
    private let recentIssuesCache = RecentListCache<RepoIssueSummary>()
    private let recentPullRequestsCache = RecentListCache<RepoPullRequestSummary>()
    private let recentReleasesCache = RecentListCache<RepoReleaseSummary>()
    private let recentWorkflowRunsCache = RecentListCache<RepoWorkflowRunSummary>()
    private let recentDiscussionsCache = RecentListCache<RepoDiscussionSummary>()
    private let recentTagsCache = RecentListCache<RepoTagSummary>()
    private let recentBranchesCache = RecentListCache<RepoBranchSummary>()
    private let recentContributorsCache = RecentListCache<RepoContributorSummary>()

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
        self.appState.session.settingsSelectedTab = .about
        SettingsOpener.shared.open()
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

    @objc func openDiscussions(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "discussions")
    }

    @objc func openTags(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "tags")
    }

    @objc func openBranches(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "branches")
    }

    @objc func openContributors(_ sender: NSMenuItem) {
        self.openRepoPath(sender: sender, path: "graphs/contributors")
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
        terminal.open(
            at: url,
            rootBookmarkData: self.appState.session.settings.localProjects.rootBookmarkData,
            ghosttyOpenMode: self.appState.session.settings.localProjects.ghosttyOpenMode
        )
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
            if self.appState.session.settings.appearance.showContributionHeader,
               case let .loggedIn(user) = self.appState.session.account {
                Task { await self.appState.loadContributionHeatmapIfNeeded(for: user.username) }
            }
            self.appState.refreshIfNeededForMenu()
            self.menuBuilder.populateMainMenu(menu)
            if let cachedWidth = self.lastMainMenuWidth {
                self.menuBuilder.refreshMenuViewHeights(in: menu, width: cachedWidth)
            } else {
                self.menuBuilder.refreshMenuViewHeights(in: menu)
            }

            let repoFullNames = Set(menu.items.compactMap { $0.representedObject as? String }.filter { $0.contains("/") })
            self.prefetchRecentLists(fullNames: repoFullNames)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let measuredWidth = self.menuBuilder.menuWidth(for: menu)
                let priorWidth = self.lastMainMenuWidth
                let shouldRemeasure = priorWidth == nil || abs(measuredWidth - (priorWidth ?? 0)) > 0.5
                self.lastMainMenuWidth = measuredWidth
                if shouldRemeasure {
                    self.menuBuilder.refreshMenuViewHeights(in: menu, width: measuredWidth)
                    menu.update()
                }
                self.menuBuilder.clearHighlights(in: menu)
                self.startObservingMenuResize(for: menu)
            }
        } else if let fullName = menu.items.first?.representedObject as? String,
                  fullName.contains("/") {
            // Repo submenu opened; prefetch so nested recent lists appear instantly.
            self.prefetchRecentLists(fullNames: [fullName])
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu === self.mainMenu {
            self.menuBuilder.clearHighlights(in: menu)
            self.stopObservingMenuResize()
        }
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        for menuItem in menu.items {
            guard let view = menuItem.view as? MenuItemHighlighting else { continue }
            let highlighted = menuItem == item && menuItem.isEnabled
            view.setHighlighted(highlighted)
        }
    }

    private func startObservingMenuResize(for menu: NSMenu) {
        self.stopObservingMenuResize()
        guard let window = menu.items.compactMap(\.view).first?.window else { return }
        self.menuResizeWindow = window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.menuWindowDidResize(_:)),
            name: NSWindow.didResizeNotification,
            object: window
        )
    }

    private func stopObservingMenuResize() {
        guard let window = self.menuResizeWindow else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: window)
        self.menuResizeWindow = nil
    }

    @objc private func menuWindowDidResize(_: Notification) {
        guard let menu = self.mainMenu else { return }
        let width = self.menuBuilder.menuWidth(for: menu)
        self.lastMainMenuWidth = width
        self.menuBuilder.refreshMenuViewHeights(in: menu, width: width)
        menu.update()
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
            let stale = cached ?? self.recentIssuesCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, rows: .issues(stale))
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
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
                }
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
            let stale = cached ?? self.recentPullRequestsCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, rows: .pullRequests(stale))
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
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
                }
            }
            menu.update()
        case .releases:
            let header = RecentMenuHeader(
                title: "Open Releases",
                action: #selector(self.openReleases),
                fullName: context.fullName,
                systemImage: "tag"
            )
            let hasLatestRelease = self.appState.session.repositories
                .first(where: { $0.fullName == context.fullName })?
                .latestRelease != nil
            let actions = hasLatestRelease
                ? [
                    RecentMenuAction(
                        title: "Open Latest Release",
                        action: #selector(self.openLatestRelease),
                        systemImage: "tag.fill",
                        representedObject: context.fullName,
                        isEnabled: true
                    )
                ]
                : []

            let cached = self.recentReleasesCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            let stale = cached ?? self.recentReleasesCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, actions: actions, rows: .releases(stale))
            } else {
                self.populateRecentListMenu(menu, header: header, actions: actions, rows: .loading)
            }
            menu.update()

            guard self.recentReleasesCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentReleasesCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentReleases(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentReleasesCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentReleasesCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, actions: actions, rows: .releases(items))
            } catch {
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, actions: actions, rows: .message("Failed to load"))
                }
            }
            menu.update()
        case .ciRuns:
            let header = RecentMenuHeader(
                title: "Open Actions",
                action: #selector(self.openActions),
                fullName: context.fullName,
                systemImage: "bolt"
            )
            let cached = self.recentWorkflowRunsCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            let stale = cached ?? self.recentWorkflowRunsCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, rows: .workflowRuns(stale))
            } else {
                self.populateRecentListMenu(menu, header: header, rows: .loading)
            }
            menu.update()

            guard self.recentWorkflowRunsCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentWorkflowRunsCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentWorkflowRuns(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentWorkflowRunsCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentWorkflowRunsCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, rows: .workflowRuns(items))
            } catch {
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
                }
            }
            menu.update()
        case .discussions:
            let header = RecentMenuHeader(
                title: "Open Discussions",
                action: #selector(self.openDiscussions),
                fullName: context.fullName,
                systemImage: "bubble.left.and.bubble.right"
            )
            let cached = self.recentDiscussionsCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            let stale = cached ?? self.recentDiscussionsCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, rows: .discussions(stale))
            } else {
                self.populateRecentListMenu(menu, header: header, rows: .loading)
            }
            menu.update()

            guard self.recentDiscussionsCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentDiscussionsCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentDiscussions(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentDiscussionsCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentDiscussionsCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, rows: .discussions(items))
            } catch {
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
                }
            }
            menu.update()
        case .tags:
            let header = RecentMenuHeader(
                title: "Open Tags",
                action: #selector(self.openTags),
                fullName: context.fullName,
                systemImage: "tag"
            )
            let cached = self.recentTagsCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            let stale = cached ?? self.recentTagsCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, rows: .tags(stale))
            } else {
                self.populateRecentListMenu(menu, header: header, rows: .loading)
            }
            menu.update()

            guard self.recentTagsCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentTagsCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentTags(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentTagsCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentTagsCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, rows: .tags(items))
            } catch {
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
                }
            }
            menu.update()
        case .branches:
            let header = RecentMenuHeader(
                title: "Open Branches",
                action: #selector(self.openBranches),
                fullName: context.fullName,
                systemImage: "point.topleft.down.curvedto.point.bottomright.up"
            )
            let cached = self.recentBranchesCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            let stale = cached ?? self.recentBranchesCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, rows: .branches(stale))
            } else {
                self.populateRecentListMenu(menu, header: header, rows: .loading)
            }
            menu.update()

            guard self.recentBranchesCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentBranchesCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentBranches(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentBranchesCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentBranchesCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, rows: .branches(items))
            } catch {
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
                }
            }
            menu.update()
        case .contributors:
            let header = RecentMenuHeader(
                title: "Open Contributors",
                action: #selector(self.openContributors),
                fullName: context.fullName,
                systemImage: "person.2"
            )
            let cached = self.recentContributorsCache.cached(for: context.fullName, now: now, maxAge: self.recentListCacheTTL)
            let stale = cached ?? self.recentContributorsCache.stale(for: context.fullName)
            if let stale {
                self.populateRecentListMenu(menu, header: header, rows: .contributors(stale))
            } else {
                self.populateRecentListMenu(menu, header: header, rows: .loading)
            }
            menu.update()

            guard self.recentContributorsCache.needsRefresh(for: context.fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentContributorsCache.task(for: context.fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.topContributors(owner: owner, name: name, limit: recentListLimit)
            }
            defer { self.recentContributorsCache.clearInflight(for: context.fullName) }
            do {
                let items = try await task.value
                self.recentContributorsCache.store(items, for: context.fullName, fetchedAt: Date())
                self.populateRecentListMenu(menu, header: header, rows: .contributors(items))
            } catch {
                if stale == nil {
                    self.populateRecentListMenu(menu, header: header, rows: .message("Failed to load"))
                }
            }
            menu.update()
        }
    }

    private func prefetchRecentLists(fullNames: Set<String>) {
        guard case .loggedIn = self.appState.session.account else { return }
        guard fullNames.isEmpty == false else { return }

        for fullName in fullNames {
            self.prefetchRecentList(fullName: fullName, kind: .issues)
            self.prefetchRecentList(fullName: fullName, kind: .pullRequests)
            self.prefetchRecentList(fullName: fullName, kind: .releases)
            self.prefetchRecentList(fullName: fullName, kind: .ciRuns)
            self.prefetchRecentList(fullName: fullName, kind: .discussions)
            self.prefetchRecentList(fullName: fullName, kind: .tags)
            self.prefetchRecentList(fullName: fullName, kind: .branches)
            self.prefetchRecentList(fullName: fullName, kind: .contributors)
        }
    }

    private func prefetchRecentList(fullName: String, kind: RepoRecentMenuKind) {
        guard let (owner, name) = self.ownerAndName(from: fullName) else { return }
        let now = Date()

        switch kind {
        case .issues:
            guard self.recentIssuesCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentIssuesCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentIssues(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentIssuesCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentIssuesCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        case .pullRequests:
            guard self.recentPullRequestsCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentPullRequestsCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentPullRequests(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentPullRequestsCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentPullRequestsCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        case .releases:
            guard self.recentReleasesCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentReleasesCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentReleases(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentReleasesCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentReleasesCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        case .ciRuns:
            guard self.recentWorkflowRunsCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentWorkflowRunsCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentWorkflowRuns(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentWorkflowRunsCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentWorkflowRunsCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        case .discussions:
            guard self.recentDiscussionsCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentDiscussionsCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentDiscussions(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentDiscussionsCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentDiscussionsCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        case .tags:
            guard self.recentTagsCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentTagsCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentTags(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentTagsCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentTagsCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        case .branches:
            guard self.recentBranchesCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentBranchesCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.recentBranches(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentBranchesCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentBranchesCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        case .contributors:
            guard self.recentContributorsCache.needsRefresh(for: fullName, now: now, maxAge: self.recentListCacheTTL) else { return }
            let task = self.recentContributorsCache.task(for: fullName) { [github = self.appState.github, recentListLimit = self.recentListLimit] in
                try await github.topContributors(owner: owner, name: name, limit: recentListLimit)
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.recentContributorsCache.clearInflight(for: fullName) }
                if let items = try? await task.value {
                    self.recentContributorsCache.store(items, for: fullName, fetchedAt: Date())
                }
            }
        }
    }

    private enum RecentMenuRows {
        case signedOut
        case loading
        case message(String)
        case issues([RepoIssueSummary])
        case pullRequests([RepoPullRequestSummary])
        case releases([RepoReleaseSummary])
        case workflowRuns([RepoWorkflowRunSummary])
        case discussions([RepoDiscussionSummary])
        case tags([RepoTagSummary])
        case branches([RepoBranchSummary])
        case contributors([RepoContributorSummary])
    }

    private struct RecentMenuHeader {
        let title: String
        let action: Selector?
        let fullName: String
        let systemImage: String?
    }

    private struct RecentMenuAction {
        let title: String
        let action: Selector
        let systemImage: String?
        let representedObject: Any
        let isEnabled: Bool
    }

    private func populateRecentListMenu(
        _ menu: NSMenu,
        header: RecentMenuHeader,
        actions: [RecentMenuAction] = [],
        rows: RecentMenuRows
    ) {
        menu.removeAllItems()

        let open = NSMenuItem(title: header.title, action: header.action, keyEquivalent: "")
        open.target = self
        open.representedObject = header.fullName
        if let systemImage = header.systemImage, let image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil) {
            image.size = NSSize(width: 14, height: 14)
            image.isTemplate = true
            open.image = image
        }
        open.isEnabled = header.action != nil
        menu.addItem(open)

        for action in actions {
            let item = NSMenuItem(title: action.title, action: action.action, keyEquivalent: "")
            item.target = self
            item.representedObject = action.representedObject
            item.isEnabled = action.isEnabled
            if let systemImage = action.systemImage, let image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil) {
                image.size = NSSize(width: 14, height: 14)
                image.isTemplate = true
                item.image = image
            }
            menu.addItem(item)
        }

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
        case let .releases(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No releases", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for release in items.prefix(self.recentListLimit) {
                self.addReleaseMenuItem(release, to: menu)
            }
            self.menuBuilder.refreshMenuViewHeights(in: menu)
        case let .workflowRuns(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No CI runs", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for run in items.prefix(self.recentListLimit) {
                self.addWorkflowRunMenuItem(run, to: menu)
            }
            self.menuBuilder.refreshMenuViewHeights(in: menu)
        case let .discussions(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No discussions", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for discussion in items.prefix(self.recentListLimit) {
                self.addDiscussionMenuItem(discussion, to: menu)
            }
            self.menuBuilder.refreshMenuViewHeights(in: menu)
        case let .tags(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No tags", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for tag in items.prefix(self.recentListLimit) {
                self.addTagMenuItem(tag, repoFullName: header.fullName, to: menu)
            }
            self.menuBuilder.refreshMenuViewHeights(in: menu)
        case let .branches(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No branches", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for branch in items.prefix(self.recentListLimit) {
                self.addBranchMenuItem(branch, repoFullName: header.fullName, to: menu)
            }
            self.menuBuilder.refreshMenuViewHeights(in: menu)
        case let .contributors(items):
            if items.isEmpty {
                let item = NSMenuItem(title: "No contributors", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
                return
            }
            for contributor in items.prefix(self.recentListLimit) {
                self.addContributorMenuItem(contributor, to: menu)
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

    private func addReleaseMenuItem(_ release: RepoReleaseSummary, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let hasAssets = release.assets.isEmpty == false
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: hasAssets) {
            ReleaseMenuItemView(release: release) { [weak self] in
                self?.open(url: release.url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = self.recentItemTooltip(title: release.name, author: release.authorLogin, updatedAt: release.publishedAt)
        if hasAssets {
            item.submenu = self.releaseAssetsMenu(for: release)
            item.target = self
            item.action = #selector(self.menuItemNoOp(_:))
        }
        menu.addItem(item)
    }

    private func addWorkflowRunMenuItem(_ run: RepoWorkflowRunSummary, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            WorkflowRunMenuItemView(run: run) { [weak self] in
                self?.open(url: run.url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = self.recentItemTooltip(title: run.name, author: run.actorLogin, updatedAt: run.updatedAt)
        menu.addItem(item)
    }

    private func addDiscussionMenuItem(_ discussion: RepoDiscussionSummary, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            DiscussionMenuItemView(discussion: discussion) { [weak self] in
                self?.open(url: discussion.url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = self.recentItemTooltip(
            title: discussion.title,
            author: discussion.authorLogin,
            updatedAt: discussion.updatedAt
        )
        menu.addItem(item)
    }

    private func addTagMenuItem(_ tag: RepoTagSummary, repoFullName: String, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            TagMenuItemView(tag: tag) { [weak self] in
                guard let self, let url = self.tagURL(repoFullName: repoFullName, tag: tag.name) else { return }
                self.open(url: url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = "\(tag.name)\n\(tag.commitSHA)"
        menu.addItem(item)
    }

    private func addBranchMenuItem(_ branch: RepoBranchSummary, repoFullName: String, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            BranchMenuItemView(branch: branch) { [weak self] in
                guard let self, let url = self.branchURL(repoFullName: repoFullName, branch: branch.name) else { return }
                self.open(url: url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = "\(branch.name)\n\(branch.commitSHA)"
        menu.addItem(item)
    }

    private func addContributorMenuItem(_ contributor: RepoContributorSummary, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            ContributorMenuItemView(contributor: contributor) { [weak self] in
                guard let url = contributor.url else { return }
                self?.open(url: url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = "\(contributor.login)\n\(contributor.contributions) contributions"
        menu.addItem(item)
    }

    private func releaseAssetsMenu(for release: RepoReleaseSummary) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        let open = NSMenuItem(title: "Open Release", action: #selector(self.openURLFromMenuItem(_:)), keyEquivalent: "")
        open.target = self
        open.representedObject = release.url
        menu.addItem(open)
        menu.addItem(.separator())

        for asset in release.assets {
            self.addReleaseAssetMenuItem(asset, to: menu)
        }

        return menu
    }

    private func addReleaseAssetMenuItem(_ asset: RepoReleaseAssetSummary, to menu: NSMenu) {
        let highlightState = MenuItemHighlightState()
        let view = MenuItemContainerView(highlightState: highlightState, showsSubmenuIndicator: false) {
            ReleaseAssetMenuItemView(asset: asset) { [weak self] in
                self?.open(url: asset.url)
            }
        }

        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = true
        item.view = MenuItemHostingView(rootView: AnyView(view), highlightState: highlightState)
        item.toolTip = asset.name
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

    private func tagURL(repoFullName: String, tag: String) -> URL? {
        guard var url = self.repoURL(for: repoFullName) else { return nil }
        url.appendPathComponent("tree")
        url.appendPathComponent(tag)
        return url
    }

    private func branchURL(repoFullName: String, branch: String) -> URL? {
        guard var url = self.repoURL(for: repoFullName) else { return nil }
        url.appendPathComponent("tree")
        url.appendPathComponent(branch)
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
        SecurityScopedBookmark.withAccess(
            to: url,
            rootBookmarkData: self.appState.session.settings.localProjects.rootBookmarkData
        ) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func menuItemNoOp(_: NSMenuItem) {}

    @objc private func openURLFromMenuItem(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        self.open(url: url)
    }

    func registerRecentListMenu(_ menu: NSMenu, context: RepoRecentMenuContext) {
        self.recentListMenuContexts[ObjectIdentifier(menu)] = context
    }

    func cachedRecentListCount(fullName: String, kind: RepoRecentMenuKind) -> Int? {
        switch kind {
        case .issues:
            self.recentIssuesCache.stale(for: fullName)?.count
        case .pullRequests:
            self.recentPullRequestsCache.stale(for: fullName)?.count
        case .releases:
            self.recentReleasesCache.stale(for: fullName)?.count
        case .ciRuns:
            self.recentWorkflowRunsCache.stale(for: fullName)?.count
        case .discussions:
            self.recentDiscussionsCache.stale(for: fullName)?.count
        case .tags:
            self.recentTagsCache.stale(for: fullName)?.count
        case .branches:
            self.recentBranchesCache.stale(for: fullName)?.count
        case .contributors:
            self.recentContributorsCache.stale(for: fullName)?.count
        }
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

    func stale(for key: String) -> [Item]? {
        self.entries[key]?.items
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
