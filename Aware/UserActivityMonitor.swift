import Cocoa

class UserActivityMonitor {
    private let eventMask: NSEventMask = [.KeyDownMask, .MouseMovedMask]

    private let sampleInterval: NSTimeInterval
    private var lastEventTimestamp: NSDate
    private var eventMonitor: AnyObject?
    private var timer: NSTimer?

    var timeSinceLastEvent: NSTimeInterval {
      get {
        return NSDate().timeIntervalSinceDate(lastEventTimestamp)
      }
    }

    init(interval: NSTimeInterval) {
        self.sampleInterval = interval
        self.lastEventTimestamp = NSDate()
    }

    @objc func start() {
        self.eventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(eventMask, handler: onEvent)
        self.timer = nil
    }

    func stop() {
        if let eventMonitor = self.eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        self.timer?.invalidate()

        self.eventMonitor = nil
        self.timer = nil
    }

    private func onEvent(event: NSEvent) {
        self.lastEventTimestamp = NSDate()
        stop()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(sampleInterval, target: self, selector: Selector("start"), userInfo: nil, repeats: false)
    }
}
