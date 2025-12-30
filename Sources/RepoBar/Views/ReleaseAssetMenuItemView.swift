import RepoBarCore
import SwiftUI

struct ReleaseAssetMenuItemView: View {
    let asset: RepoReleaseAssetSummary
    let onOpen: () -> Void
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        RecentItemRowView(alignment: .center, onOpen: self.onOpen) {
            Image(systemName: "doc")
                .font(.caption)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
        } content: {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.asset.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let size = self.sizeText {
                        Text(size)
                            .font(.caption)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                    }

                    Text("\(self.asset.downloadCount) downloads")
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                }
            }
        }
    }

    private var sizeText: String? {
        guard let bytes = self.asset.sizeBytes else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
