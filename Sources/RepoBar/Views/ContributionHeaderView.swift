import RepoBarCore
import SwiftUI

struct ContributionHeaderView: View {
    let username: String
    @EnvironmentObject var session: Session
    @EnvironmentObject var appState: AppState
    @State private var isLoading = true
    @State private var failed = false

    var body: some View {
        if self.session.settings.showHeatmap {
            VStack(alignment: .leading, spacing: 6) {
                self.content
            }
            .task(id: self.session.hasLoadedRepositories) {
                guard self.session.hasLoadedRepositories else { return }
                self.isLoading = true
                self.failed = false
                await self.appState.loadContributionHeatmapIfNeeded(for: self.username)
                await MainActor.run {
                    self.isLoading = false
                    self.failed = self.session.contributionHeatmap.isEmpty
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !self.session.hasLoadedRepositories {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 72, alignment: .center)
        } else if self.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 72, alignment: .center)
        } else if self.failed {
            VStack(spacing: 6) {
                Text(self.session.contributionError ?? "Unable to load contributions right now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    self.appState.clearContributionCache()
                    Task { await self.appState.loadContributionHeatmapIfNeeded(for: self.username) }
                }
                .buttonStyle(.borderless)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
        } else {
            let filtered = HeatmapFilter.filter(self.session.contributionHeatmap, span: self.session.settings.heatmapSpan)
            HeatmapView(cells: filtered, accentTone: self.session.settings.accentTone)
                .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 72, alignment: .leading)
                .padding(.horizontal, -8)
                .accessibilityLabel("Contribution graph for \(self.username)")
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(height: 80)
            .accessibilityLabel("Contribution graph unavailable")
    }

    private var placeholderOverlay: some View {
        self.placeholder.overlay { ProgressView() }
    }
}
