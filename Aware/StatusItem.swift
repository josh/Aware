import Cocoa

class StatusItem: NSObject {
    let item: NSStatusItem

    @IBOutlet weak var menu: NSMenu!

    override init() {
        self.item = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
        super.init()
    }

    override func awakeFromNib() {
        self.item.menu = menu
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
}
