import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    var timerStart: NSDate?
    var lastActivity: NSDate?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if let button = statusItem.button {
            button.title = "0s"
        }

        let menu = NSMenu()
        menu.addItemWithTitle("Quit", action: "terminate:", keyEquivalent: "q")
        statusItem.menu = menu

        timerStart = NSDate()
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "onTick", userInfo: nil, repeats: true)

        lastActivity = NSDate()
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true])
        NSEvent.addGlobalMonitorForEventsMatchingMask([NSEventMask.KeyDownMask, NSEventMask.MouseMovedMask], handler: onGlobalEvent)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }

    func onTick() {
        let sinceStart = NSDate().timeIntervalSinceDate(lastActivity!)
        let secondsSinceStart = NSInteger(sinceStart) % 60
        statusItem.button!.title = "\(secondsSinceStart)s"
    }

    func onGlobalEvent(event: NSEvent) {
        lastActivity = NSDate()
    }
}
