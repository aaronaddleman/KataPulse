//
//  Kata_PulseApp.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import Speech

@main
struct Kata_PulseApp: App {
    let persistenceController = PersistenceController.shared
    let watchManager = WatchManager.shared // Use the singleton instance
    @StateObject private var dataManager = DataManager(persistenceController: PersistenceController.shared)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(dataManager) // Provide the data manager as an environment object
                .onAppear {
                    watchManager.startSession()
                    dataManager.fetchTrainingSessions() // Fetch training sessions at launch
                }
        }
    }
    
    private func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized.")
            case .denied:
                print("Speech recognition authorization denied.")
            case .restricted:
                print("Speech recognition restricted on this device.")
            case .notDetermined:
                print("Speech recognition not determined.")
            @unknown default:
                print("Unknown authorization status.")
            }
        }
    }
}
