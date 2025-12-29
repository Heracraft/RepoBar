import RepoBarCore
import SwiftUI

struct HeatmapView: View {
    let cells: [HeatmapCell]
    let accentTone: AccentTone
    private let height: CGFloat?
    @Environment(\.menuItemHighlighted) private var isHighlighted
    private var summary: String {
        let total = self.cells.map(\.count).reduce(0, +)
        let maxVal = self.cells.map(\.count).max() ?? 0
        return "Commit activity heatmap, total \(total) commits, max \(maxVal) in a day."
    }

    init(cells: [HeatmapCell], accentTone: AccentTone = .githubGreen, height: CGFloat? = nil) {
        self.cells = cells
        self.accentTone = accentTone
        self.height = height
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let columns = HeatmapLayout.columnCount(cellCount: self.cells.count)
            let cellSide = HeatmapLayout.cellSide(
                forHeight: size.height,
                width: size.width,
                columns: columns
            )
            let grid = HeatmapLayout.reshape(cells: self.cells, columns: columns)
            let xOffset: CGFloat = 0
            Canvas { context, _ in
                for (x, column) in grid.enumerated() {
                    for (y, cell) in column.enumerated() {
                        let origin = CGPoint(
                            x: xOffset + CGFloat(x) * (cellSide + HeatmapLayout.spacing),
                            y: CGFloat(y) * (cellSide + HeatmapLayout.spacing)
                        )
                        let rect = CGRect(origin: origin, size: CGSize(width: cellSide, height: cellSide))
                        let path = Path(roundedRect: rect, cornerRadius: cellSide * HeatmapLayout.cornerRadiusFactor)
                        context.fill(path, with: .color(self.color(for: cell.count)))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: self.height)
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
                base.opacity(0.36),
                base.opacity(0.56),
                base.opacity(0.72),
                base.opacity(0.86),
                base.opacity(0.96)
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

}

enum HeatmapLayout {
    static let rows = 7
    static let minColumns = 53
    static let spacing: CGFloat = 0.5
    static let cornerRadiusFactor: CGFloat = 0.12
    static let minCellSide: CGFloat = 2
    static let maxCellSide: CGFloat = 10

    static func columnCount(cellCount: Int) -> Int {
        let dataColumns = max(1, Int(ceil(Double(cellCount) / Double(rows))))
        return max(dataColumns, minColumns)
    }

    static func cellSide(for height: CGFloat) -> CGFloat {
        let totalSpacingY = CGFloat(rows - 1) * spacing
        let availableHeight = max(height - totalSpacingY, 0)
        let side = availableHeight / CGFloat(rows)
        return max(minCellSide, min(maxCellSide, floor(side)))
    }

    static func cellSide(forHeight height: CGFloat, width: CGFloat, columns: Int) -> CGFloat {
        let heightSide = cellSide(for: height)
        let totalSpacingX = CGFloat(max(columns - 1, 0)) * spacing
        let availableWidth = max(width - totalSpacingX, 0)
        let widthSide = availableWidth / CGFloat(max(columns, 1))
        let side = floor(min(heightSide, widthSide))
        return max(minCellSide, min(maxCellSide, side))
    }

    static func reshape(cells: [HeatmapCell], columns: Int) -> [[HeatmapCell]] {
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
