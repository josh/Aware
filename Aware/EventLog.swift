import Foundation

class EventLog {
    let path: String
    var stream: NSOutputStream?

    init(path: String) {
        self.path = path
    }

    func open() {
        self.stream = NSOutputStream(toFileAtPath: path, append: true)
        self.stream?.open()
    }

    func close() {
        self.stream?.close()
        self.stream = nil
    }

    func logUserActivity() {
        let data = NSMutableData()
        var number: Double = NSDate().timeIntervalSince1970
        data.appendBytes(&number, length: sizeof(Double))

        let bytes = UnsafePointer<UInt8>(data.bytes)
        self.stream?.write(bytes, maxLength: data.length)
    }
}
