import Kingfisher
import RepoBarCore
import SwiftUI

struct DiscussionMenuItemView: View {
    let discussion: RepoDiscussionSummary
    let onOpen: () -> Void
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            self.avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(self.discussion.title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(MenuHighlightStyle.primary(self.isHighlighted))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let category = self.discussion.categoryName, category.isEmpty == false {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                    }

                    if let author = self.discussion.authorLogin, author.isEmpty == false {
                        Text(author)
                            .font(.caption)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                    }

                    Text(RelativeFormatter.string(from: self.discussion.updatedAt, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)

                    Spacer(minLength: 2)

                    if self.discussion.commentCount > 0 {
                        MenuStatBadge(label: nil, value: self.discussion.commentCount, systemImage: "text.bubble")
                    }
                }
            }

            Spacer(minLength: 2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { self.onOpen() }
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = self.discussion.authorAvatarURL {
            KFImage(url)
                .placeholder { self.avatarPlaceholder }
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
                .clipShape(Circle())
        } else {
            self.avatarPlaceholder
                .frame(width: 20, height: 20)
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color(nsColor: .separatorColor))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            )
    }
}
