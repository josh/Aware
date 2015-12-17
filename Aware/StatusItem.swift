import Cocoa

class StatusItem: NSObject {
    private let item: NSStatusItem

    @IBOutlet weak var menu: NSMenu! {
        didSet {
            item.menu = menu
        }
    }

    var button: NSStatusBarButton {
        return item.button!
    }

    override init() {
        self.item = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
        super.init()
    }
}
