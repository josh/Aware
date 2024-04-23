//
//  SettingsView.swift
//  Aware
//
//  Created by Joshua Peek on 4/22/24.
//

import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage("userIdleSeconds") private var userIdleSeconds: Int = 120
    @AppStorage("formatStyle") private var timerFormatStyle: TimerFormatStyle.Style = .condensedAbbreviated
    @AppStorage("showSeconds") private var showSeconds: Bool = false

    @State private var lastLoginItemRegistration: Result<Bool, Error>?

    var body: some View {
        Form {
            Section(header: Text("Timer")) {
                Picker("Format Style", selection: $timerFormatStyle) {
                    ForEach(TimerFormatStyle.Style.allCases, id: \.self) { style in
                        Text(style.exampleText)
                    }
                }

                Toggle("Show Seconds", isOn: $showSeconds)

                TextField(value: $userIdleSeconds, format: .number) {
                    Text("Idle Seconds")
                }

                Toggle("Open at Login", isOn: openAtLogin)
                    .toggleStyle(.checkbox)
            }
        }
    }

    var openAtLogin: Binding<Bool> {
        .init {
            switch lastLoginItemRegistration {
            case let .success(enabled): return enabled
            default: return SMAppService.mainApp.status == .enabled
            }
        } set: { enabled in
            lastLoginItemRegistration = Result {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                return SMAppService.mainApp.status == .enabled
            }
        }
    }
}

#Preview {
    SettingsView()
}
