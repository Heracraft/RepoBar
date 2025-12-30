import AppKit
import RepoBarCore
import SwiftUI

struct WorkflowRunMenuItemView: View {
    let run: RepoWorkflowRunSummary
    let onOpen: () -> Void
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        RecentItemRowView(alignment: .top, onOpen: self.onOpen) {
            Circle()
                .fill(self.statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
        } content: {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.run.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let branch = self.run.branch, branch.isEmpty == false {
                        Text(branch)
                            .font(.caption)
                            .monospaced()
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                    }

                    if let event = self.run.event, event.isEmpty == false {
                        Text(event)
                            .font(.caption)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                    }

                    if let actor = self.run.actorLogin, actor.isEmpty == false {
                        Text(actor)
                            .font(.caption)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 2)

                    Text(RelativeFormatter.string(from: self.run.updatedAt, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                }
            }
        }
    }

    private var statusColor: Color {
        MenuCIBadge.dotColor(for: self.run.status, isLightAppearance: self.isLightAppearance, isHighlighted: self.isHighlighted)
    }

    private var isLightAppearance: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
    }
}
