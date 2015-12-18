import Foundation

class NSTimeIntervalFormatter {
    /**
        Formats time interval as a human readable duration string.

        - Parameters:
            - interval: The time interval in seconds.

        - Returns: A `String`.
     */
    func stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let minutes = NSInteger(interval) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }
}
