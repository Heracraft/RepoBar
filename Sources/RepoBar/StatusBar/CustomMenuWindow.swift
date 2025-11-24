import AppKit
import SwiftUI

/// Lightweight floating window used for the rich left-click view.
final class CustomMenuWindow: NSWindow {
    private var hostingView: NSHostingView<AnyView>?
    var onShow: (() -> Void)?
    var onHide: (() -> Void)?

    init(contentView: some View) {
        let view = AnyView(contentView)
        let hosting = NSHostingView(rootView: view)
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar
        self.hostingView = hosting
        self.contentView = hosting
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard button.window?.screen != nil else { return }
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        let windowSize = frameRect(forContentRect: frame).size
        let origin = NSPoint(
            x: buttonFrame.midX - windowSize.width / 2,
            y: buttonFrame.minY - windowSize.height - 8
        )
        setFrame(NSRect(origin: origin, size: windowSize), display: true)
        orderFrontRegardless()
        makeKey()
        self.onShow?()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        orderOut(nil)
        self.onHide?()
    }

    var isWindowVisible: Bool {
        isVisible
    }
}
