import Foundation

class EventLog {
    enum EventType: UInt8 {
        case Open = 1
        case Quit = 2
        case Active = 3
        case Idle = 4
        case DisplayAsleep = 5
        case Sleep = 6
    }

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

    func logEvent(type: EventType, timestamp: NSDate) {
        let data = NSMutableData()
        var typeInt: UInt8 = type.rawValue
        var number: Double = timestamp.timeIntervalSince1970
        data.appendBytes(&typeInt, length: sizeof(UInt8))
        data.appendBytes(&number, length: sizeof(Double))

        let bytes = UnsafePointer<UInt8>(data.bytes)
        self.stream?.write(bytes, maxLength: data.length)
    }
}
