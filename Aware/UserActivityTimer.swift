import Cocoa

class UserActivityTimer {
    var startTimestamp: NSDate

    var onUpdate: NSTimeInterval -> Void

    init(onUpdate: NSTimeInterval -> Void) {
        self.startTimestamp = NSDate()
        self.onUpdate = onUpdate
    }

    // kCGAnyInputEventType isn't part of CGEventType enum
    // defined in <CoreGraphics/CGEventTypes.h>
    let AnyInputEventType = CGEventType(rawValue: UInt32.max)!

    func start() {
        NSTimer.scheduledTimer(30, userInfo: nil, repeats: true) { _ in
            let now = NSDate()

            let sinceUserActivity = CGEventSourceSecondsSinceLastEventType(.CombinedSessionState, self.AnyInputEventType)
            if (NSInteger(sinceUserActivity) > 2 * 60) {
                self.startTimestamp = now
            }

            let sinceStart = now.timeIntervalSinceDate(self.startTimestamp)
            self.onUpdate(sinceStart)
        }
    }
}
