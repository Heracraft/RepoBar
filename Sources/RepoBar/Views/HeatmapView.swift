import SwiftUI

struct HeatmapView: View {
    let cells: [HeatmapCell]
    let accentTone: AccentTone
    private let columns = 53 // roughly a year

    init(cells: [HeatmapCell], accentTone: AccentTone = .githubGreen) {
        self.cells = cells
        self.accentTone = accentTone
    }

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
        let palette = self.palette()
        switch count {
        case 0: return palette[0]
        case 1...3: return palette[1]
        case 4...7: return palette[2]
        case 8...12: return palette[3]
        default: return palette[4]
        }
    }

    private func palette() -> [Color] {
        switch self.accentTone {
        case .githubGreen:
            return [
                Color(nsColor: .controlBackgroundColor),
                Color(red: 0.78, green: 0.93, blue: 0.79),
                Color(red: 0.51, green: 0.82, blue: 0.56),
                Color(red: 0.2, green: 0.65, blue: 0.32),
                Color(red: 0.12, green: 0.45, blue: 0.2),
            ]
        case .system:
            let accent = Color.accentColor
            return [
                Color(nsColor: .controlBackgroundColor),
                accent.opacity(0.25),
                accent.opacity(0.45),
                accent.opacity(0.7),
                accent.opacity(0.9),
            ]
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
            Array(padded[index..<min(index + rows, padded.count)])
        }
    }
}
