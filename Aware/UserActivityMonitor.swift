import Cocoa

class UserActivityMonitor {
    private let eventMask: NSEventMask = [.KeyDownMask, .MouseMovedMask]
    private let sampleInterval: NSTimeInterval = 30

    private var lastEventTimestamp: NSTimeInterval?
    private var eventMonitor: AnyObject?

    var timeSinceLastEvent: NSTimeInterval

    init() {
        self.timeSinceLastEvent = NSTimeInterval()
        start()
    }

    @objc func start() {
        self.eventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(eventMask, handler: onEvent)
    }

    func stop() {
        if let eventMonitor = self.eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    private func throttle(seconds: NSTimeInterval) {
        stop()
        NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: Selector("start"), userInfo: nil, repeats: false)
    }

    private func onEvent(event: NSEvent) {
        if let lastTimestamp = self.lastEventTimestamp {
            self.timeSinceLastEvent = event.timestamp - lastTimestamp
        }

        self.lastEventTimestamp = event.timestamp
        throttle(sampleInterval)
    }
}
