import Cocoa

class SampledEvent {
    let mask: NSEventMask
    let sampleInterval: NSTimeInterval
    let handler: (NSEvent) -> Void

    private var eventMonitor: AnyObject?
    private var timer: NSTimer?

    init(mask: NSEventMask, sampleInterval: NSTimeInterval, handler: (NSEvent) -> Void) {
        self.mask = mask
        self.sampleInterval = sampleInterval
        self.handler = handler

        start()
    }

    func removeMonitor() {
        stop()
    }

    private func start() {
        self.eventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(self.mask, handler: onEvent)
        self.timer = nil
    }

    private func stop() {
        if let eventMonitor = self.eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        self.timer?.invalidate()

        self.eventMonitor = nil
        self.timer = nil
    }

    private func onEvent(event: NSEvent) {
        self.handler(event)
        stop()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(sampleInterval, target: self, selector: Selector("onInterval"), userInfo: nil, repeats: false)
    }

    @objc func onInterval() {
        start()
    }
}

extension NSEvent {
    class func addGlobalMonitorForEventsMatchingMask(mask: NSEventMask, sampleInterval: NSTimeInterval, handler: (NSEvent) -> Void) -> SampledEvent {
        return SampledEvent(mask: mask, sampleInterval: sampleInterval, handler: handler)
    }
}
