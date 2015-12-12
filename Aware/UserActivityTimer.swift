import Cocoa

class UserActivityTimer {
    let eventMask: NSEventMask = [.KeyDownMask, .MouseMovedMask, .LeftMouseDownMask]

    var startTimestamp: NSDate
    var userActivityTimestamp: NSDate

    var onUpdate: NSTimeInterval -> Void

    init(onUpdate: NSTimeInterval -> Void) {
        self.userActivityTimestamp = NSDate()
        self.startTimestamp = NSDate()
        self.onUpdate = onUpdate
    }

    func start() {
        NSEvent.addGlobalMonitorForEventsMatchingMask(eventMask, interval: 30) { event in
            self.userActivityTimestamp = NSDate()
        }

        NSTimer.scheduledTimer(30, userInfo: nil, repeats: true) { _ in
            let now = NSDate()

            let sinceUserActivity = now.timeIntervalSinceDate(self.userActivityTimestamp)
            if (NSInteger(sinceUserActivity) > 2 * 60) {
                self.startTimestamp = now
            }

            let sinceStart = now.timeIntervalSinceDate(self.startTimestamp)
            self.onUpdate(sinceStart)
        }
    }
}
