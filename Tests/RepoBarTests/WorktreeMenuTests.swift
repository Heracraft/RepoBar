import AppKit
@testable import RepoBar
import Testing

struct WorktreeMenuTests {
    @MainActor
    @Test
    func worktreeMenuItem_wiresActionAndPayload() {
        let manager = StatusBarMenuManager(appState: AppState())
        let path = URL(fileURLWithPath: "/tmp/worktree", isDirectory: true)
        let item = manager.makeLocalWorktreeMenuItem(.init(
            displayPath: "/tmp/worktree",
            branch: "main",
            isCurrent: true,
            upstream: nil,
            aheadCount: nil,
            behindCount: nil,
            lastCommitDate: nil,
            lastCommitAuthor: nil,
            dirtySummary: nil,
            path: path,
            fullName: "owner/repo"
        ))

        #expect(item.target != nil)
        #expect(item.action != nil)
        #expect(item.representedObject is StatusBarMenuManager.LocalWorktreeAction)
    }
}
