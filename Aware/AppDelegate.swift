import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var statusItem: StatusItem!

    var timerStart: NSDate!

    // Redraw button every minute
    let buttonRefreshRate: NSTimeInterval = 60

    // After N seconds, reset the timer
    var userIdleTimeout: NSTimeInterval = 0

    // User configurable idle time in minutes (defaults to 2m)
    //   defaults write com.github.josh.Aware idle -int 2
    let defaultIdleKey = "idle"
    let defaultIdle = 2

    // kCGAnyInputEventType isn't part of CGEventType enum
    // defined in <CoreGraphics/CGEventTypes.h>
    let AnyInputEventType = CGEventType(rawValue: UInt32.max)!

    let defaults = NSUserDefaults.standardUserDefaults()

    func applicationDidFinishLaunching(notification: NSNotification) {
        timerStart = NSDate()

        let idleValue = (defaults.objectForKey(defaultIdleKey) as? Int) ?? defaultIdle
        userIdleTimeout = Double(idleValue * 60)

        updateButton()
        NSTimer.scheduledTimer(buttonRefreshRate, userInfo: nil, repeats: true) { _ in self.updateButton() }
    }

    func updateButton() {
        let sinceUserActivity = CGEventSourceSecondsSinceLastEventType(.CombinedSessionState, AnyInputEventType)
        if (sinceUserActivity > userIdleTimeout) {
            timerStart = NSDate()
            updateButton()
        }

        let duration = NSDate().timeIntervalSinceDate(timerStart)
        let minutes = NSInteger(duration) / 60
        statusItem.button.title = "\(minutes)m"
    }
}
