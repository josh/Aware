import Cocoa

class UserActivityMonitor: NSObject {
    private let eventMask: NSEventMask = [.KeyDownMask, .MouseMovedMask]
    private let sampleInterval: NSTimeInterval = 30

    private var lastEventTimestamp: NSDate
    private var eventMonitor: AnyObject?
    private var timer: NSTimer?

    var timeSinceLastEvent: NSTimeInterval {
      get {
        return NSDate().timeIntervalSinceDate(lastEventTimestamp)
      }
    }

    override init() {
        self.lastEventTimestamp = NSDate()
        super.init()
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

    private func throttle(seconds: NSTimeInterval) {
        stop()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: Selector("start"), userInfo: nil, repeats: false)
    }

    private func onEvent(event: NSEvent) {
        self.lastEventTimestamp = NSDate()
        throttle(sampleInterval)
    }
}
