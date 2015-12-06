import Foundation

extension NSTimer {
    private class NSTimerHandler {
        let handler: Void -> Void

        init(handler: Void -> Void) {
            self.handler = handler
        }

        @objc func callHandler() {
            self.handler()
        }
    }

    class func scheduledTimerWithTimeInterval(ti: NSTimeInterval, userInfo: AnyObject?, repeats: Bool, handler: Void -> Void) -> NSTimer {
        return NSTimer.scheduledTimerWithTimeInterval(ti, target: NSTimerHandler(handler: handler), selector: Selector("callHandler"), userInfo: userInfo, repeats: repeats)
    }
}
