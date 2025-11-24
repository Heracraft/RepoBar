import AppKit

/// Updates the menubar icon to reflect overall status.
@MainActor
final class StatusBarIconController {
    func update(button: NSStatusBarButton?, session: Session) {
        guard let button else { return }
        let status = self.aggregateStatus(for: session)
        let image = self.icon(for: status)
        button.image = image
        button.image?.isTemplate = true
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
        case .loggedOut: "icloud.slash"
        case .green: "checkmark.circle"
        case .yellow: "exclamationmark.circle"
        case .red: "xmark.octagon"
        }
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: symbolName)
    }
}

enum AggregateStatus {
    case loggedOut
    case green
    case yellow
    case red
}
