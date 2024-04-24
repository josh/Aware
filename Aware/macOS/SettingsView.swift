//
//  SettingsView.swift
//  Aware
//
//  Created by Joshua Peek on 4/22/24.
//

import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage("reset") private var resetTimer: Bool = false
    @AppStorage("userIdleSeconds") private var userIdleSeconds: Int = 120
    @AppStorage("formatStyle") private var timerFormatStyle: TimerFormatStyle.Style = .condensedAbbreviated
    @AppStorage("showSeconds") private var showSeconds: Bool = false

    @State private var lastLoginItemRegistration: Result<Bool, Error>?

    var body: some View {
        Form {
            Section {
                Picker("Format Style:", selection: $timerFormatStyle) {
                    ForEach(TimerFormatStyle.Style.allCases, id: \.self) { style in
                        Text(style.exampleText)
                    }
                }

                Toggle("Show Seconds", isOn: $showSeconds)
            }

            Spacer()
                .frame(width: 0, height: 0)
                .padding(.top)

            Section {
                LabeledContent("Reset after:") {
                    TextField("Idle Seconds", value: $userIdleSeconds, format: .number)
                        .multilineTextAlignment(.trailing)
                        .labelsHidden()
                        .frame(width: 50)
                    Stepper("Idle Seconds", value: $userIdleSeconds, step: 30)
                        .labelsHidden()
                    Text("seconds of inactivity")
                        .padding(.leading, 5)
                }

                Button("Reset Timer") {
                    self.resetTimer = true
                }
            }

            Spacer()
                .frame(width: 0, height: 0)
                .padding(.top)

            Section {
                LabeledContent("Login Item:") {
                    Toggle("Open at Login", isOn: openAtLogin)
                }
            }
        }
        .padding()
        .frame(width: 350)
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
