import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    var timerStart: NSDate?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if let button = statusItem.button {
            button.attributedTitle = NSAttributedString(string: "0s")
        }

        let menu = NSMenu()
        menu.addItemWithTitle("Quit", action: "terminate:", keyEquivalent: "q")
        statusItem.menu = menu

        timerStart = NSDate()
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "onTick", userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }

    func onTick() {
        let sinceStart = NSDate().timeIntervalSinceDate(timerStart!)
        let secondsSinceStart = NSInteger(sinceStart) % 60
        statusItem.button!.attributedTitle = NSAttributedString(string: "\(secondsSinceStart)s")
    }
}
