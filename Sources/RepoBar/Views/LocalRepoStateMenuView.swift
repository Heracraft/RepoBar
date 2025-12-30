import AppKit
import RepoBarCore
import SwiftUI

struct LocalRepoStateMenuView: View {
    let status: LocalRepoStatus
    let onSync: () -> Void
    let onRebase: () -> Void
    let onReset: () -> Void
    let onOpenFinder: () -> Void
    let onOpenTerminal: () -> Void

    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            self.headerRow
            if self.detailsLine.isEmpty == false {
                Text(self.detailsLine)
                    .font(.caption2)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            }
            if self.status.dirtyFiles.isEmpty == false {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(self.status.dirtyFiles.prefix(MenuStyle.submenuDirtyFileLimit)), id: \.self) { file in
                        Text("- \(file)")
                            .font(.caption2)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            HStack(spacing: 12) {
                self.actionButton(
                    title: "Sync",
                    systemImage: "arrow.triangle.2.circlepath",
                    enabled: self.syncEnabled,
                    action: self.onSync
                )
                self.actionButton(
                    title: "Rebase",
                    systemImage: "arrow.triangle.branch",
                    enabled: self.rebaseEnabled,
                    action: self.onRebase
                )
                self.actionButton(
                    title: "Reset",
                    systemImage: "arrow.counterclockwise",
                    enabled: self.resetEnabled,
                    action: self.onReset
                )
                Spacer(minLength: 8)
                self.actionButton(
                    title: "Finder",
                    systemImage: "folder",
                    enabled: true,
                    action: self.onOpenFinder
                )
                self.actionButton(
                    title: "Terminal",
                    systemImage: "terminal",
                    enabled: true,
                    action: self.onOpenTerminal
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var headerRow: some View {
        HStack(spacing: 6) {
            Image(systemName: self.status.syncState.symbolName)
                .font(.caption2)
                .foregroundStyle(self.localSyncColor(for: self.status.syncState))
            Text(self.status.branch)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            Text(self.status.syncDetail)
                .font(.caption2)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            if let worktreeName = self.status.worktreeName {
                Text("Worktree \(worktreeName)")
                    .font(.caption2)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            }
            Spacer(minLength: 8)
        }
    }

    private var detailsLine: String {
        var parts: [String] = []
        if let upstream = self.status.upstreamBranch {
            parts.append("Upstream \(upstream)")
        }
        if let dirty = self.status.dirtyCounts, dirty.isEmpty == false {
            parts.append("Dirty \(dirty.summary)")
        }
        if let fetch = self.status.lastFetchAt {
            let age = RelativeFormatter.string(from: fetch, relativeTo: Date())
            parts.append("Fetched \(age)")
        }
        return parts.joined(separator: " · ")
    }

    private var syncEnabled: Bool {
        self.status.upstreamBranch != nil && self.status.isClean
    }

    private var rebaseEnabled: Bool {
        self.status.upstreamBranch != nil && self.status.isClean
    }

    private var resetEnabled: Bool {
        self.status.upstreamBranch != nil
    }

    private func actionButton(title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption2)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? MenuHighlightStyle.primary(self.isHighlighted) : .secondary)
        .opacity(enabled ? 1 : 0.5)
        .disabled(!enabled)
    }

    private func localSyncColor(for state: LocalSyncState) -> Color {
        if self.isHighlighted { return MenuHighlightStyle.selectionText }
        let isLightAppearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        switch state {
        case .synced:
            return isLightAppearance
                ? Color(nsColor: NSColor(srgbRed: 0.12, green: 0.55, blue: 0.24, alpha: 1))
                : Color(nsColor: NSColor(srgbRed: 0.23, green: 0.8, blue: 0.4, alpha: 1))
        case .behind:
            return isLightAppearance ? Color(nsColor: .systemOrange) : Color(nsColor: .systemYellow)
        case .ahead:
            return isLightAppearance ? Color(nsColor: .systemBlue) : Color(nsColor: .systemTeal)
        case .diverged:
            return isLightAppearance ? Color(nsColor: .systemOrange) : Color(nsColor: .systemYellow)
        case .dirty:
            return Color(nsColor: .systemRed)
        case .unknown:
            return MenuHighlightStyle.secondary(self.isHighlighted)
        }
    }
}
