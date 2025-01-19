//
//  SettingsTab.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct SettingsTab: View {
    var body: some View {
        NavigationView {
            GlobalSettingsView()
                .navigationTitle("Settings & Communication")
        }
    }
}
