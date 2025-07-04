//
//  GlobalSettingsView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 11/29/24.
//

import SwiftUI

struct GlobalSettingsView: View {
    @ObservedObject private var watchManager = WatchManager.shared
    @AppStorage("quizTestingMode") private var quizTestingMode: String = "simple"
    @State private var showEraseConfirmation = false

    var body: some View {
        Form {
            Section(header: Text("Device Status")) {
                HStack {
                    Text("Watch Paired:")
                    Spacer()
                    Text(watchManager.isPaired ? "Yes" : "No")
                        .foregroundColor(watchManager.isPaired ? .green : .red)
                }

                HStack {
                    Text("Watch Reachable:")
                    Spacer()
                    Text(watchManager.isReachable ? "Yes" : "No")
                        .foregroundColor(watchManager.isReachable ? .green : .red)
                }

                HStack {
                    Text("App Installed:")
                    Spacer()
                    Text(watchManager.isWatchAppInstalled ? "Yes" : "No")
                        .foregroundColor(watchManager.isWatchAppInstalled ? .green : .red)
                }

                // Refresh button to update connectivity status
                Button(action: {
                    watchManager.updateConnectivityStatus()
                }) {
                    HStack {
                        Spacer()
                        Text("Refresh Status")
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Section(header: Text("Quiz Mode Testing")) {
                Picker("Testing Mode", selection: $quizTestingMode) {
                    Text("Simple Match").tag("simple")
                    Text("Fuzzy Match").tag("fuzzy")
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section(header: Text("Preferences")) {
                Toggle("Enable Randomization", isOn: .constant(true))
                Toggle("Enable Feet Together", isOn: .constant(false))
            }

            Section(header: Text("Communication")) {
                Button("Send Test Message to Watch") {
                    watchManager.sendMessageToWatch(["command": "test"])
                }

                Button("Send Test Message to iPhone") {
                    watchManager.sendMessageToiPhone(["command": "test"])
                }
            }
            
            Section(header: Text("Data Management")) {
                Button(action: {
                    showEraseConfirmation = true // ✅ Show confirmation dialog
                }) {
                    Text("Erase All Data")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Global Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Erase All Data?",
            isPresented: $showEraseConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Erase", role: .destructive) {
                    clearAllData()
                }
            },
            message: {
                Text("This will permanently delete all your data. This action cannot be undone.")
            }
        )
    }
}
