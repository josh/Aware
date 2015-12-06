import Cocoa

class UserActivityMonitor: NSObject {
    private let eventMask: NSEventMask = [.KeyDownMask, .MouseMovedMask]
    private let sampleInterval: NSTimeInterval = 30

    private var lastEventTimestamp: NSTimeInterval?
    private var eventMonitor: AnyObject?

    var timeSinceLastEvent: NSTimeInterval

    override init() {
        self.timeSinceLastEvent = NSTimeInterval()
        super.init()
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
