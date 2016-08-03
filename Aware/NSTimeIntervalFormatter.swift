//
//  NSTimeIntervalFormatter.swift
//  Aware
//
//  Created by Joshua Peek on 12/18/15.
//  Copyright © 2015 Joshua Peek. All rights reserved.
//

import Foundation

class NSTimeIntervalFormatter {
    /**
        Formats time interval as a human readable duration string.

        - Parameters:
            - interval: The time interval in seconds.

        - Returns: A `String`.
     */
    func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = NSInteger(interval) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
    }
}
