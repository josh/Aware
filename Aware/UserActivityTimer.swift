import Cocoa

class UserActivityTimer {

    let monitor: UserActivityMonitor
    var startTimestamp: NSDate
    var timer: NSTimer?

    var onUpdate: NSTimeInterval -> Void

    init(onUpdate: NSTimeInterval -> Void) {
        self.monitor = UserActivityMonitor(interval: 30)
        self.startTimestamp = NSDate()
        self.onUpdate = onUpdate
    }

    func start() {
        self.monitor.start()
        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("onTick"), userInfo: nil, repeats: true)
    }

    func stop() {
        self.monitor.stop()
        self.timer?.invalidate()
        self.timer = nil
    }

    @objc func onTick() {
        let sinceUserActivity = monitor.timeSinceLastEvent
        if (NSInteger(sinceUserActivity) > 60) {
            self.startTimestamp = NSDate()
        }

        let sinceStart = NSDate().timeIntervalSinceDate(startTimestamp)
        onUpdate(sinceStart)
    }
}
