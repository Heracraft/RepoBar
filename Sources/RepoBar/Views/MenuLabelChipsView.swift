import RepoBarCore
import SwiftUI

struct MenuLabelChipsView: View {
    let labels: [RepoIssueLabel]
    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        FlowLayout(itemSpacing: 6, lineSpacing: 4) {
            ForEach(self.labels, id: \.self) { label in
                MenuLabelChipView(label: label, isHighlighted: self.isHighlighted)
            }
        }
    }
}

private struct MenuLabelChipView: View {
    let label: RepoIssueLabel
    let isHighlighted: Bool

    var body: some View {
        let base = MenuLabelColor.color(from: self.label.colorHex) ?? Color(nsColor: .separatorColor)

        Text(self.label.name)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(self.isHighlighted ? .white.opacity(0.95) : base.opacity(0.95))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(self.isHighlighted ? .white.opacity(0.18) : base.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(self.isHighlighted ? .white.opacity(0.35) : base.opacity(0.45), lineWidth: 1)
            )
    }
}

private enum MenuLabelColor {
    static func color(from hex: String) -> Color? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

private struct FlowLayout: Layout {
    let itemSpacing: CGFloat
    let lineSpacing: CGFloat

    init(itemSpacing: CGFloat = 6, lineSpacing: CGFloat = 4) {
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let width = proposal.width ?? 240
        return self.measure(in: width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = self.measure(in: bounds.width, subviews: subviews)
        for placement in result.placements {
            placement.subview.place(
                at: CGPoint(x: bounds.minX + placement.origin.x, y: bounds.minY + placement.origin.y),
                proposal: ProposedViewSize(width: placement.size.width, height: placement.size.height)
            )
        }
    }

    private struct Placement {
        let subview: LayoutSubview
        let origin: CGPoint
        let size: CGSize
    }

    private struct MeasureResult {
        let size: CGSize
        let placements: [Placement]
    }

    private func measure(in availableWidth: CGFloat, subviews: Subviews) -> MeasureResult {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        var placements: [Placement] = []
        placements.reserveCapacity(subviews.count)

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let exceeds = (x > 0) && (x + size.width > availableWidth)
            if exceeds {
                x = 0
                y += rowHeight + self.lineSpacing
                rowHeight = 0
            }

            placements.append(Placement(subview: subview, origin: CGPoint(x: x, y: y), size: size))
            x += size.width + self.itemSpacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x)
        }

        let totalHeight = y + rowHeight
        return MeasureResult(size: CGSize(width: min(maxX, availableWidth), height: totalHeight), placements: placements)
    }
}
