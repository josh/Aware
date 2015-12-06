import Cocoa

class UserActivityTimer {
    let eventMask: NSEventMask = [.KeyDownMask, .MouseMovedMask]

    var startTimestamp: NSDate
    var userActivityTimestamp: NSDate

    var onUpdate: NSTimeInterval -> Void

    init(onUpdate: NSTimeInterval -> Void) {
        self.userActivityTimestamp = NSDate()
        self.startTimestamp = NSDate()
        self.onUpdate = onUpdate
    }

    func start() {
        NSEvent.addGlobalMonitorForEventsMatchingMask(eventMask, sampleInterval: 30) { event in
            self.userActivityTimestamp = NSDate()
        }

        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("onTick"), userInfo: nil, repeats: true)
    }

    @objc func onTick() {
        let now = NSDate()

        let sinceUserActivity = now.timeIntervalSinceDate(userActivityTimestamp)
        if (NSInteger(sinceUserActivity) > 2 * 60) {
            self.startTimestamp = now
        }

        let sinceStart = now.timeIntervalSinceDate(startTimestamp)
        onUpdate(sinceStart)
    }
}
