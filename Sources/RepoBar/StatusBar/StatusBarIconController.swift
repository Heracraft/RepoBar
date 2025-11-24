import AppKit

/// Updates the menubar icon to reflect overall status.
@MainActor
final class StatusBarIconController {
    private var cache: [AggregateStatus: NSImage] = [:]

    func update(button: NSStatusBarButton?, session: Session) {
        guard let button else { return }
        let status = self.aggregateStatus(for: session)
        button.image = self.icon(for: status)
        button.image?.isTemplate = false
    }

    private func aggregateStatus(for session: Session) -> AggregateStatus {
        // Simple rollup: if any repo red => red, else if yellow => yellow, else green/gray by login
        if session.account == .loggedOut { return .loggedOut }
        if session.repositories.contains(where: { $0.ciStatus == .failing }) { return .red }
        if session.repositories.contains(where: { $0.ciStatus == .pending }) { return .yellow }
        return .green
    }

    private func icon(for status: AggregateStatus) -> NSImage? {
        if let cached = self.cache[status] { return cached }
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size, flipped: false) { rect in
            let bgColor: NSColor = switch status {
            case .loggedOut: .quaternaryLabelColor
            case .green: NSColor.systemGreen
            case .yellow: NSColor.systemYellow
            case .red: NSColor.systemRed
            }
            let outline = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 5, yRadius: 5)
            bgColor.setFill()
            outline.fill()
            NSColor.labelColor.withAlphaComponent(0.15).setStroke()
            outline.lineWidth = 1
            outline.stroke()

            // Draw a tiny "repo" glyph: two stacked lines.
            let line1 = NSBezierPath(roundedRect: NSRect(x: 5, y: 11, width: 10, height: 3), xRadius: 1.5, yRadius: 1.5)
            let line2 = NSBezierPath(roundedRect: NSRect(x: 5, y: 6, width: 7, height: 3), xRadius: 1.5, yRadius: 1.5)
            NSColor.white.setFill()
            line1.fill()
            line2.fill()

            // Status dot bottom-right for extra clarity.
            let dotRect = NSRect(x: rect.maxX - 7, y: rect.minY + 3, width: 4, height: 4)
            let dot = NSBezierPath(ovalIn: dotRect)
            NSColor.black.withAlphaComponent(0.25).setStroke()
            bgColor.darker(by: 0.15).setFill()
            dot.fill()
            dot.stroke()
            return true
        }
        image.isTemplate = false
        self.cache[status] = image
        return image
    }
}

enum AggregateStatus {
    case loggedOut
    case green
    case yellow
    case red
}

extension NSColor {
    fileprivate func darker(by amount: CGFloat) -> NSColor {
        let rgb = self.usingColorSpace(.deviceRGB) ?? self
        return NSColor(
            calibratedRed: max(rgb.redComponent - amount, 0),
            green: max(rgb.greenComponent - amount, 0),
            blue: max(rgb.blueComponent - amount, 0),
            alpha: rgb.alphaComponent)
    }
}
