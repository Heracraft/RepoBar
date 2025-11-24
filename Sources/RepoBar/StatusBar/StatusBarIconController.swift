import AppKit

/// Updates the menubar icon to reflect overall status.
@MainActor
final class StatusBarIconController {
    func update(button: NSStatusBarButton?, session: Session) {
        guard let button else { return }
        let status = self.aggregateStatus(for: session)
        let icon = self.icon(for: status)
        button.image = icon
        button.alternateImage = icon // ensure highlighted state also uses template tinting
        button.image?.isTemplate = true // let macOS tint for native look
    }

    private func aggregateStatus(for session: Session) -> AggregateStatus {
        // Simple rollup: if any repo red => red, else if yellow => yellow, else green/gray by login
        if session.account == .loggedOut { return .loggedOut }
        if session.repositories.contains(where: { $0.ciStatus == .failing }) { return .red }
        if session.repositories.contains(where: { $0.ciStatus == .pending }) { return .yellow }
        return .green
    }

    private func icon(for status: AggregateStatus) -> NSImage? {
        let symbolName = switch status {
        case .loggedOut: "tray"
        case .green: "tray.fill"
        case .yellow: "tray.fill"
        case .red: "tray.fill"
        }

        let base = NSImage(systemSymbolName: symbolName, accessibilityDescription: "RepoBar")
        // Overlay a tiny status dot; keep template-friendly by using a monochrome badge glyph.
        let dotName = switch status {
        case .green: "smallcircle.filled.circle"
        case .yellow: "exclamationmark.circle.fill"
        case .red: "xmark.circle.fill"
        case .loggedOut: "slash.circle"
        }
        let dot = NSImage(systemSymbolName: dotName, accessibilityDescription: nil)

        guard let base, let dot else { return self.templated(base ?? dot) }
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        base.draw(in: NSRect(origin: .zero, size: image.size))
        dot.draw(in: NSRect(x: image.size.width - 10, y: 2, width: 8, height: 8))
        image.unlockFocus()
        return self.templated(image)
    }

    private func templated(_ image: NSImage?) -> NSImage? {
        image?.isTemplate = true
        return image
    }
}

enum AggregateStatus {
    case loggedOut
    case green
    case yellow
    case red
}
