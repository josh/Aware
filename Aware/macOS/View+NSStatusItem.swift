//
//  View+NSStatusItem.swift
//  Aware
//
//  Created by Joshua Peek on 4/25/24.
//

#if canImport(AppKit)

import AppKit
import SwiftUI

extension View {
    @MainActor
    func bindStatusItem(_ statusItem: Binding<NSStatusItem?>) -> some View {
        onAppear {
            let statusItems = NSApp.windows.filter { window in
                window.className == "NSStatusBarWindow"
            }.compactMap { window in
                window.value(forKey: "statusItem") as? NSStatusItem
            }

            assert(!statusItems.isEmpty, "no NSStatusItems found")
            assert(statusItems.count == 1, "multiple NSStatusItems found")
            statusItem.wrappedValue = statusItems.first
        }
    }
}

#endif
