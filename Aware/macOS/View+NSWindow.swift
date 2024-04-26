//
//  View+NSWindow.swift
//  Aware
//
//  Created by Joshua Peek on 4/25/24.
//

#if canImport(AppKit)

import AppKit
import SwiftUI

private struct WindowAccessorView: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        Task {
            assert(view.window != nil, "window accessor fail to detect window")
            self.window = view.window
        }
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}

extension View {
    func bindWindow(_ window: Binding<NSWindow?>) -> some View {
        background(WindowAccessorView(window: window))
    }
}

#endif
