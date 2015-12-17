import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var statusItem: StatusItem!

    var timerStart: NSDate!

    // Redraw button every minute
    let buttonRefreshRate: NSTimeInterval = 60

    // Reset timer after 2m of inactivity
    let userInactivityTimeout: NSTimeInterval = 2 * 60

    // kCGAnyInputEventType isn't part of CGEventType enum
    // defined in <CoreGraphics/CGEventTypes.h>
    let AnyInputEventType = CGEventType(rawValue: UInt32.max)!

    func applicationDidFinishLaunching(notification: NSNotification) {
        timerStart = NSDate()

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
        if (sinceUserActivity > userInactivityTimeout) {
            timerStart = NSDate()
            updateButton()
        }

        let duration = NSDate().timeIntervalSinceDate(timerStart)
        let minutes = NSInteger(duration) / 60
        statusItem.button.title = "\(minutes)m"
    }
}
