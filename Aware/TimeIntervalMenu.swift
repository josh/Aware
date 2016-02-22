//
//  TimeIntervalMenu.swift
//  Aware
//
//  Created by Joshua Peek on 2/13/16.
//  Copyright © 2016 Joshua Peek. All rights reserved.
//

import Cocoa

class TimeIntervalMenu: NSMenu {
    func setTimeInterval(ti: NSTimeInterval) {
        for item in itemArray {
            if let timeIntervalItem = item as? TimeIntervalMenuItem {
                item.state = timeIntervalItem.value == ti ? 1 : 0
            }
        }
    }
}
