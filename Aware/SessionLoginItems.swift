//
//  LoginItems.swift
//  Aware
//
//  Created by Joshua Peek on 12/30/15.
//  Copyright © 2015 Joshua Peek. All rights reserved.
//

import Foundation

@available(OSX, deprecated=10.11)
struct SessionLoginItems {
    static func addURL(url: NSURL) {
        guard let list = SharedFileList.create(SharedFileList.sessionLoginItems) else {
            return
        }

        SharedFileList.insertItemURL(list, afterItem: SharedFileList.itemBeforeFirst, url: url)
    }

    static func removeURL(url: NSURL) {
        guard let list = SharedFileList.create(SharedFileList.sessionLoginItems) else {
            return
        }

        if let item = findURL(url) {
            SharedFileList.removeItem(list, item: item)
        }
    }

    static func findURL(url: NSURL) -> SharedFileList.Item? {
        guard let list = SharedFileList.create(SharedFileList.sessionLoginItems),
                 items = SharedFileList.copySnapshot(list) as? [LSSharedFileListItemRef] else {
            return nil
        }

        for item in items {
            if let url = SharedFileList.copyResolvedURL(item) where url.isEqual(url) {
                return item
            }
        }

        return nil
    }
}
