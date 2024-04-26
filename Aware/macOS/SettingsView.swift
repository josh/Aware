//
//  SettingsView.swift
//  Aware
//
//  Created by Joshua Peek on 4/22/24.
//

#if os(macOS)

import OSLog
import ServiceManagement
import SwiftUI

private nonisolated(unsafe) let logger = Logger(
    subsystem: "com.awaremac.Aware", category: "SettingsView"
)

struct SettingsView: View {
    @AppStorage("reset") private var resetTimer: Bool = false
    @AppStorage("userIdleSeconds") private var userIdleSeconds: Int = 120
    @AppStorage("formatStyle") private var timerFormatStyle: TimerFormatStyle.Style = .condensedAbbreviated
    @AppStorage("showSeconds") private var showSeconds: Bool = false

    @State private var lastLoginItemRegistration: Result<Bool, Error>?

    @State private var exportingLogs: Bool = false
    @State private var showExportErrored: Bool = false

    @State private var window: NSWindow?
    @State private var windowIsVisible: Bool = false

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

            Spacer()
                .frame(width: 0, height: 0)
                .padding(.top)

            Section {
                Button(exportingLogs ? "Exporting Developer Logs..." : "Export Developer Logs") {
                    self.exportingLogs = true
                    Task<Void, Never>(priority: .low) {
                        do {
                            let logURL = try await exportLogs()
                            NSWorkspace.shared.activateFileViewerSelecting([logURL])
                            self.showExportErrored = false
                        } catch {
                            self.showExportErrored = true
                        }
                        self.exportingLogs = false
                    }
                }
                .disabled(exportingLogs)
                .alert(isPresented: $showExportErrored) {
                    Alert(
                        title: Text("Export Error"),
                        message: Text("Couldn't export logs"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
        .padding()
        .frame(width: 350)
        .bindWindow($window)
        .onChange(of: windowIsVisible) { oldValue, newValue in
            logger.debug("Window visibility change: \(oldValue) -> \(newValue)")

            if oldValue == false && newValue == true {
                NSApp.activateAggressively()
            }
        }
        .task(id: window) {
            guard let window else {
                assertionFailure("no window is set")
                return
            }

            self.windowIsVisible = window.isVisible

            logger.debug("Starting to observe occlusion state changes for \(window)")
            let notifications = NotificationCenter.default.notifications(
                named: NSWindow.didChangeOcclusionStateNotification,
                object: window
            ).map { _ in () }

            for await _ in notifications {
                logger.debug("Window occlusion state changed for \(window): \(window.isVisible)")
                self.windowIsVisible = window.isVisible
            }

            logger.debug("Finished observing occlusion state changes for \(window)")
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

#endif
