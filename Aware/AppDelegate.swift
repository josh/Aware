import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var statusItem: StatusItem!

    var timerStart: NSDate!

    // Redraw button every minute
    let buttonRefreshRate: NSTimeInterval = 60

    // After N seconds, reset the timer
    var userIdleSeconds: NSTimeInterval = 0

    // User configurable idle time in seconds (defaults to 2 minutes)
    //   defaults write com.github.josh.Aware userIdleSeconds -int 120
    let defaultUserIdleSecondsKey = "userIdleSeconds"
    let defaultUserIdleSeconds: NSTimeInterval = 2 * 60

    // kCGAnyInputEventType isn't part of CGEventType enum
    // defined in <CoreGraphics/CGEventTypes.h>
    let AnyInputEventType = CGEventType(rawValue: UInt32.max)!

    let defaults = NSUserDefaults.standardUserDefaults()

    func applicationDidFinishLaunching(notification: NSNotification) {
        timerStart = NSDate()

        userIdleSeconds = ((defaults.objectForKey(defaultUserIdleSecondsKey) as? NSTimeInterval) ?? defaultUserIdleSeconds)

        updateButton()
        NSTimer.scheduledTimer(buttonRefreshRate, userInfo: nil, repeats: true) { _ in self.updateButton() }

        let notificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
        notificationCenter.addObserverForName(NSWorkspaceWillSleepNotification, object: nil, queue: nil) { _ in self.resetTimer() }
        notificationCenter.addObserverForName(NSWorkspaceDidWakeNotification, object: nil, queue: nil) { _ in self.resetTimer() }
    }

    func resetTimer() {
        timerStart = NSDate()
        self.updateButton()
    }

    func updateButton() {
        let sinceUserActivity = CGEventSourceSecondsSinceLastEventType(.CombinedSessionState, AnyInputEventType)
        if (sinceUserActivity > userIdleSeconds) {
            timerStart = NSDate()
        }

        let duration = NSDate().timeIntervalSinceDate(timerStart)
        statusItem.button.title = formatDuration(duration)
    }

    func formatDuration(duration: NSTimeInterval) -> String {
        let minutes = NSInteger(duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }
}
