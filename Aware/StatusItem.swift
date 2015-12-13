import Cocoa

class StatusItem: NSObject, NSMenuDelegate {
    let item: NSStatusItem

    @IBOutlet weak var menu: NSMenu!

    override init() {
        self.item = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
        super.init()
    }

    let TrustedCheckOptionPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String

    override func awakeFromNib() {
        self.item.menu = menu

        setDuration(NSTimeInterval())
        UserActivityTimer(onUpdate: { duration in
            self.setDuration(duration)
        }).start()
    }

    func setDuration(duration: NSTimeInterval) {
        if let button = self.item.button {
            button.title = formatDuration(duration)
        }
    }

    func formatDuration(duration: NSTimeInterval) -> String {
        let seconds = NSInteger(duration)
        let minutes = seconds / 60
        return "\(minutes)m"
    }

    @IBAction func enableKeyboardMonitoring(sender: NSMenuItem) {
        AXIsProcessTrustedWithOptions([TrustedCheckOptionPrompt: true])
    }

    func menuNeedsUpdate(menu: NSMenu) {
        menu.itemArray[0].hidden = AXIsProcessTrusted()
    }
}
