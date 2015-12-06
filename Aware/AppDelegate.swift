import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var userActivityMonitor: UserActivityMonitor!
    @IBOutlet weak var menu: NSMenu!

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    var timerStart: NSDate?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if let button = statusItem.button {
            button.title = formatDuration(NSTimeInterval())
        }
        statusItem.menu = menu

        timerStart = NSDate()
        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "onTick", userInfo: nil, repeats: true)

        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true])
        userActivityMonitor.start()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }

    func onTick() {
        let sinceUserActivity = userActivityMonitor.timeSinceLastEvent
        if (NSInteger(sinceUserActivity) > 60) {
            timerStart = NSDate()
        }

        let sinceStart = NSDate().timeIntervalSinceDate(timerStart!)
        statusItem.button!.title = formatDuration(sinceStart)
    }

    func formatDuration(duration: NSTimeInterval) -> String {
        let seconds = NSInteger(duration)
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}
