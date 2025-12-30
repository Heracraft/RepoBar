import RepoBarCore
import SwiftUI

struct BranchMenuItemView: View {
    let branch: RepoBranchSummary
    let onOpen: () -> Void
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.caption)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(self.branch.name)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                        .lineLimit(1)

                    if self.branch.isProtected {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    }
                }

                Text(self.shortSHA)
                    .font(.caption)
                    .monospaced()
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(1)
            }

            Spacer(minLength: 2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { self.onOpen() }
    }

    private var shortSHA: String {
        String(self.branch.commitSHA.prefix(7))
    }
}
