import SwiftUI

struct LocalWorktreeMenuRowView: View {
    let path: String
    let branch: String
    let isCurrent: Bool
    let onSelect: (() -> Void)?

    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        let row = HStack(alignment: .firstTextBaseline, spacing: MenuStyle.submenuIconSpacing) {
            Image(systemName: self.isCurrent ? "checkmark" : "circle")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .frame(width: MenuStyle.submenuIconColumnWidth, alignment: .center)
                .alignmentGuide(.firstTextBaseline) { dimensions in
                    dimensions[VerticalAlignment.center] + MenuStyle.submenuIconBaselineOffset
                }

            Text(self.path)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            Text(self.branch)
                .font(.caption2)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)

        if let onSelect {
            row
                .contentShape(Rectangle())
                .onTapGesture { onSelect() }
        } else {
            row
        }
    }
}
