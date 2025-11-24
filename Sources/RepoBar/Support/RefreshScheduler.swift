import Foundation

@MainActor
final class RefreshScheduler: ObservableObject {
    private var timer: Timer?
    private var interval: TimeInterval = RefreshInterval.fiveMinutes.seconds
    private var tickHandler: (() -> Void)?

    func configure(interval: TimeInterval, tick: @escaping () -> Void) {
        self.interval = interval
        self.tickHandler = tick
        self.restart()
    }

    func restart() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.tickHandler?() }
        }
        self.timer?.fire()
    }

    func forceRefresh() {
        self.tickHandler?()
    }
}
