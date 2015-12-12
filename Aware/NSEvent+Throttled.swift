import Cocoa

// Install throttled global event handler to monitor high frequency events without destroying battery life.
extension NSEvent {
    /**
        Installs an event monitor that receives copies of events posted to other applications. The time between events will be at least the `interval`.

        - Parameters:
            - mask: An event mask specifying which events you wish to monitor. See `NSEventMaskFromType` for possible values.
            - interval: The minimum number of seconds between firings of events.
            - block: The event handler block object. It is passed the event to monitor. You are unable to change the event, merely observe it.

        - Returns: A `ThrottledEvent` that may be disabled.
     */
    public class func addGlobalMonitorForEventsMatchingMask(mask: NSEventMask, interval: NSTimeInterval, handler: NSEvent -> Void) -> ThrottledEvent {
        return ThrottledEvent(mask: mask, interval: interval, handler: handler)
    }
}

public class ThrottledEvent {
    private let mask: NSEventMask
    private let interval: NSTimeInterval
    private let handler: NSEvent -> Void

    private var eventMonitor: AnyObject?
    private var timer: NSTimer?

    init(mask: NSEventMask, interval: NSTimeInterval, handler: NSEvent -> Void) {
        self.mask = mask
        self.interval = interval
        self.handler = handler

        addMonitor()
    }

    private func onEvent(event: NSEvent) {
        handler(event)
        removeMonitor()
        timer = NSTimer.scheduledTimer(interval, userInfo: nil, repeats: false, fire: onTimerFired)
    }

    private func onTimerFired(timer: NSTimer) {
        addMonitor()
    }

    private func addMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(mask, handler: onEvent)
    }

    /**
        Remove the specified event monitor.
     */
    func removeMonitor() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        timer?.invalidate()

        eventMonitor = nil
        timer = nil
    }
}
