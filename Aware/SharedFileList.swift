//
//  SharedFileList.swift
//  Aware
//
//  Created by Joshua Peek on 12/30/15.
//  Copyright © 2015 Joshua Peek. All rights reserved.
//

import Foundation

@available(OSX, deprecated=10.11)
struct SharedFileList {
    typealias List = LSSharedFileListRef
    typealias Item = LSSharedFileListItemRef

    // "com.apple.LSSharedFileList.SessionLoginItems"
    static let sessionLoginItems: String = kLSSharedFileListSessionLoginItems.takeRetainedValue() as String

    static let itemBeforeFirst: Item = kLSSharedFileListItemBeforeFirst.takeRetainedValue()
    // static let itemLast: Item = kLSSharedFileListItemLast.takeRetainedValue()

    @available(OSX, introduced=10.5, deprecated=10.11)
    static func create(listType: String) -> List? {
        return LSSharedFileListCreate(nil, listType, nil).takeRetainedValue() as List?
    }

    @available(OSX, introduced=10.5, deprecated=10.11)
    static func insertItemURL(list: List, afterItem: Item, url: NSURL) -> Item {
        return LSSharedFileListInsertItemURL(list, afterItem, nil, nil, url as CFURLRef, nil, nil).takeRetainedValue()
    }

    @available(OSX, introduced=10.5, deprecated=10.11)
    static func removeItem(list: List, item: Item) {
        LSSharedFileListItemRemove(list, item)
    }

    @available(OSX, introduced=10.5, deprecated=10.11)
    static func copySnapshot(list: List) -> NSArray {
        return LSSharedFileListCopySnapshot(list, nil).takeRetainedValue()
    }

    @available(OSX, introduced=10.10, deprecated=10.11)
    static func copyResolvedURL(item: Item) -> NSURL? {
        return LSSharedFileListItemCopyResolvedURL(item, 0, nil).takeRetainedValue()
    }
}
