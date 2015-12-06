import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var userActivityMonitor: UserActivityMonitor!
    @IBOutlet weak var statusItem: StatusItem!

    var timerStart: NSDate?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem.setDuration(NSTimeInterval())

        timerStart = NSDate()
        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "onTick", userInfo: nil, repeats: true)

        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true])
        userActivityMonitor.start()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        userActivityMonitor.stop()
    }

    func onTick() {
        let sinceUserActivity = userActivityMonitor.timeSinceLastEvent
        if (NSInteger(sinceUserActivity) > 60) {
            timerStart = NSDate()
        }

        let sinceStart = NSDate().timeIntervalSinceDate(timerStart!)
        statusItem.setDuration(sinceStart)
    }
}
