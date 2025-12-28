import RepoBarCore
import SwiftUI

struct HeatmapView: View {
    let cells: [HeatmapCell]
    let accentTone: AccentTone
    private let rows = 7
    private let minColumns = 53
    private let spacing: CGFloat = 0.5
    @Environment(\.menuItemHighlighted) private var isHighlighted
    private var summary: String {
        let total = self.cells.map(\.count).reduce(0, +)
        let maxVal = self.cells.map(\.count).max() ?? 0
        return "Commit activity heatmap, total \(total) commits, max \(maxVal) in a day."
    }

    init(cells: [HeatmapCell], accentTone: AccentTone = .githubGreen) {
        self.cells = cells
        self.accentTone = accentTone
    }

    var body: some View {
        let columns = self.columnCount
        let grid = HeatmapLayout.reshape(cells: self.cells, columns: columns, rows: self.rows)
        Canvas { context, size in
            let cellSide = self.cellSide(for: size)
            for (x, column) in grid.enumerated() {
                for (y, cell) in column.enumerated() {
                    let origin = CGPoint(
                        x: CGFloat(x) * (cellSide + self.spacing),
                        y: CGFloat(y) * (cellSide + self.spacing)
                    )
                    let rect = CGRect(origin: origin, size: CGSize(width: cellSide, height: cellSide))
                    let path = Path(roundedRect: rect, cornerRadius: cellSide * 0.12)
                    context.fill(path, with: .color(self.color(for: cell.count)))
                }
            }
        }
        .aspectRatio(CGFloat(columns) / CGFloat(self.rows), contentMode: .fit)
        .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 60, alignment: .leading)
        .accessibilityLabel(self.summary)
        .accessibilityElement(children: .ignore)
    }

    private func color(for count: Int) -> Color {
        let palette = self.palette()
        switch count {
        case 0: return palette[0]
        case 1 ... 3: return palette[1]
        case 4 ... 7: return palette[2]
        case 8 ... 12: return palette[3]
        default: return palette[4]
        }
    }

    private func palette() -> [Color] {
        if self.isHighlighted {
            let base = Color(nsColor: .selectedMenuItemTextColor)
            return [
                base.opacity(0.14),
                base.opacity(0.24),
                base.opacity(0.38),
                base.opacity(0.52),
                base.opacity(0.7)
            ]
        }
        switch self.accentTone {
        case .githubGreen:
            return [
                Color(nsColor: .quaternaryLabelColor),
                Color(red: 0.74, green: 0.86, blue: 0.75).opacity(0.6),
                Color(red: 0.56, green: 0.76, blue: 0.6).opacity(0.65),
                Color(red: 0.3, green: 0.62, blue: 0.38).opacity(0.7),
                Color(red: 0.18, green: 0.46, blue: 0.24).opacity(0.75)
            ]
        case .system:
            let accent = Color.accentColor
            return [
                Color(nsColor: .quaternaryLabelColor),
                accent.opacity(0.22),
                accent.opacity(0.36),
                accent.opacity(0.5),
                accent.opacity(0.65)
            ]
        }
    }

    private var columnCount: Int {
        let columns = Int(ceil(Double(self.cells.count) / Double(self.rows)))
        return max(columns, self.minColumns)
    }

    private func cellSide(for size: CGSize) -> CGFloat {
        let totalSpacingX = CGFloat(self.columnCount - 1) * self.spacing
        let totalSpacingY = CGFloat(self.rows - 1) * self.spacing
        let availableWidth = max(size.width - totalSpacingX, 0)
        let availableHeight = max(size.height - totalSpacingY, 0)
        let side = min(availableWidth / CGFloat(self.columnCount), availableHeight / CGFloat(self.rows))
        return max(2, min(10, floor(side)))
    }
}

enum HeatmapLayout {
    static func reshape(cells: [HeatmapCell], columns: Int, rows: Int) -> [[HeatmapCell]] {
        var padded = cells
        if padded.count < columns * rows {
            let missing = columns * rows - padded.count
            padded.append(contentsOf: Array(repeating: HeatmapCell(date: Date(), count: 0), count: missing))
        }
        return stride(from: 0, to: padded.count, by: rows).map { index in
            Array(padded[index ..< min(index + rows, padded.count)])
        }
    }
}
