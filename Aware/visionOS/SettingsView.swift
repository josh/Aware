//
//  SettingsView.swift
//  Aware
//
//  Created by Joshua Peek on 2/19/24.
//

#if os(visionOS)

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var glassBackground: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Glass Background", isOn: $glassBackground)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .toolbarRole(.navigationStack)
        }
    }
}

#Preview(traits: .fixedLayout(width: 400, height: 250)) {
    SettingsView(
        glassBackground: .constant(true)
    )
}

#endif
