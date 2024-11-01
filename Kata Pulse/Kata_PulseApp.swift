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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    watchManager.startSession() // Example usage
                }
        }
    }
}
