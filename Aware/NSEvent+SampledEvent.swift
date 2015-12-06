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
        eventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(mask, handler: onEvent)
        timer = nil
    }

    private func stop() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        timer?.invalidate()

        eventMonitor = nil
        timer = nil
    }

    private func onEvent(event: NSEvent) {
        handler(event)
        stop()
        timer = NSTimer.scheduledTimerWithTimeInterval(sampleInterval, userInfo: nil, repeats: false, handler: start)
    }
}

extension NSEvent {
    class func addGlobalMonitorForEventsMatchingMask(mask: NSEventMask, sampleInterval: NSTimeInterval, handler: (NSEvent) -> Void) -> SampledEvent {
        return SampledEvent(mask: mask, sampleInterval: sampleInterval, handler: handler)
    }
}
