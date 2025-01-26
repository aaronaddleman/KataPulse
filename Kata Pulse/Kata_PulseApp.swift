//
//  Kata_PulseApp.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI

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
}
