//
//  Timer+Block.swift
//  Aware
//
//  Created by Joshua Peek on 12/06/15.
//  Copyright © 2015 Joshua Peek.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

// Alternative API for timer creation with a block.
// Inspired by proposed Swift corelib interface:
//   https://github.com/apple/swift-corelibs-foundation/blob/7836f63/Foundation/NSTimer.swift#L52-L60
extension Timer {
    private class TimerHandler {
        let _fire: (Timer) -> Void

        init(_ fire: @escaping (Timer) -> Void) {
            self._fire = fire
        }

        @objc func fire(_ timer: Timer) {
            self._fire(timer)
        }
    }

    /**
        Creates and returns a new `Timer` object and schedules it on the current run loop in the default mode.

        - Parameters:
            - seconds: The number of seconds between firings of the timer. If seconds is less than or equal to 0.0, this method chooses the nonnegative value of 0.1 milliseconds instead.
            - userInfo: The user info for the timer. The timer maintains a strong reference to this object until it (the timer) is invalidated. This parameter may be nil.
            - repeats: If true, the timer will repeatedly reschedule itself until invalidated. If false, the timer will be invalidated after it fires.
            - fire: The block to call when the timer fires. The timer maintains a strong reference to target until it (the timer) is invalidated.

        - Returns: A new `Timer` object, configured according to the specified parameters.
     */
    public class func scheduledTimer(_ ti: TimeInterval, userInfo: AnyObject?, repeats: Bool, fire: @escaping (Timer) -> Void) -> Timer {
        return Timer.scheduledTimer(timeInterval: ti, target: TimerHandler(fire), selector: #selector(TimerHandler.fire(_:)), userInfo: userInfo, repeats: repeats)
    }
}
