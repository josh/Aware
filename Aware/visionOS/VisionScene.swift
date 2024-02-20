//
//  VisionScene.swift
//  Aware
//
//  Created by Joshua Peek on 2/16/24.
//

#if os(visionOS)

import SwiftUI

struct VisionScene: Scene {
    @Environment(\.scenePhase) private var scenePhase
    @State private var protectedDataAvailablity = ProtectedDataAvailablity()
    @State private var startDate: Date?

    // TODO: Persist in scene storage
    @State private var glassBackground: Bool = true

    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            TimelineView(.everyMinute) { context in
                let duration = context.date.timeIntervalSince(startDate ?? .now)
                Text(duration, format: .custom)
                    .lineLimit(1)
                    .padding()
                    .font(.system(size: 900))
                    .minimumScaleFactor(0.01)
                    .glassBackgroundEffect(displayMode: self.glassBackground ? .always : .never)
                    .onTapGesture {
                        showSettings.toggle()
                    }
            }
            .popover(isPresented: $showSettings) {
                SettingsView(glassBackground: $glassBackground)
                    .frame(width: 400, height: 250)
            }
        }
        .defaultSize(CGSize(width: 200, height: 100))
        .windowResizability(.contentMinSize)
        .windowStyle(.plain)
        .onChange(of: scenePhase, initial: true) { _, newValue in
            switch newValue {
            case .active, .inactive:
                if self.startDate == nil {
                    print("scenePhase change started timer")
                    self.startDate = .now
                }
            case .background:
                ()
            default:
                ()
            }
        }
        .onChange(of: protectedDataAvailablity.isAvailable) { oldValue, newValue in
            if oldValue == false && newValue == true {
                if self.startDate == nil {
                    print("protectedDataAvailablity change started timer")
                    self.startDate = .now
                }
            } else if oldValue == true && newValue == false {
                print("protectedDataAvailablity stopped timer")
                self.startDate = nil
            }
        }
    }
}

#endif
