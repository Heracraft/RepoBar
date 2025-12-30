import RepoBarCore
import SwiftUI

struct TagMenuItemView: View {
    let tag: RepoTagSummary
    let onOpen: () -> Void
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        RecentItemRowView(alignment: .center, onOpen: self.onOpen) {
            Image(systemName: "tag")
                .font(.caption)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
        } content: {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.tag.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)

                Text(self.shortSHA)
                    .font(.caption)
                    .monospaced()
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(1)
            }
        }
    }

    private var shortSHA: String {
        String(self.tag.commitSHA.prefix(7))
    }
}
