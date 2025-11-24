import SwiftUI

struct HeatmapView: View {
    let cells: [HeatmapCell]
    private let columns = 53 // roughly a year

    var body: some View {
        let rows = 7
        let grid = HeatmapLayout.reshape(cells: self.cells, columns: self.columns, rows: rows)
        HStack(alignment: .top, spacing: 3) {
            ForEach(Array(grid.enumerated()), id: \.offset) { _, column in
                VStack(spacing: 3) {
                    ForEach(column) { cell in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(self.color(for: cell.count))
                            .frame(width: 10, height: 10)
                            .accessibilityLabel(self.dateLabel(cell))
                    }
                }
            }
        }
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: Color(nsColor: .controlBackgroundColor)
        case 1 ... 3: Color(red: 0.78, green: 0.93, blue: 0.79)
        case 4 ... 7: Color(red: 0.51, green: 0.82, blue: 0.56)
        case 8 ... 12: Color(red: 0.2, green: 0.65, blue: 0.32)
        default: Color(red: 0.12, green: 0.45, blue: 0.2)
        }
    }

    private func dateLabel(_ cell: HeatmapCell) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: cell.date)): \(cell.count) commits"
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
