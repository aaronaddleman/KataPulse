//
//  ContentViewSessionsTab.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct SessionsTab: View {
    let trainingSessions: [TrainingSessionEntity]
    let dataManager: DataManager
    @Binding var showCreateView: Bool
    @Binding var showEditView: Bool
    @Binding var selectedSession: TrainingSessionEntity?

    var body: some View {
        NavigationView {
            VStack {
                if dataManager.trainingSessions.isEmpty {
                    Text("No training sessions available.")
                        .font(.headline)
                        .padding()
                        .onAppear {
                            print("No sessions found, refreshing data...")
                            dataManager.fetchTrainingSessions()
                        }
                } else {
                    TrainingSessionList(
                        selectedSession: $selectedSession,
                        showEditView: $showEditView
                    )
                    .environmentObject(dataManager)
                }
            }
            .navigationTitle("Training Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCreateView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("CreateTrainingSessionButton")
                }
            }
            .sheet(isPresented: $showCreateView, onDismiss: {
                // Refresh the data when returning from create view
                print("Create view dismissed, refreshing data...")
                
                // Force a refresh of the database and UI
                DispatchQueue.main.async {
                    dataManager.fetchTrainingSessions()
                    
                    // Additional reload after a short delay to ensure UI is updated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dataManager.fetchTrainingSessions()
                        dataManager.shouldRefresh.toggle() // Force SwiftUI to refresh
                    }
                }
            }) {
                CreateTrainingSessionView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showEditView, onDismiss: {
                // Refresh the data when returning from edit view
                print("Edit view dismissed, refreshing data...")
                
                // Force a refresh of the database and UI
                DispatchQueue.main.async {
                    dataManager.fetchTrainingSessions()
                    
                    // Additional reload after a short delay to ensure UI is updated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dataManager.fetchTrainingSessions()
                        dataManager.shouldRefresh.toggle() // Force SwiftUI to refresh
                    }
                }
            }) {
                EditTrainingSessionWrapperView(selectedSession: selectedSession)
                    .environmentObject(dataManager)
            }
        }
    }
}

struct EditTrainingSessionWrapperView: View {
    let selectedSession: TrainingSessionEntity?

    var body: some View {
        Group {
            if let session = selectedSession {
                
                CreateTrainingSessionView(editingSession: session)
                    .onAppear {
                        print("Editing session: \(session.name ?? "Unnamed session")")
                    }
            } else {
                Text("Error: No session selected.")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
                    .onAppear {
                        print("Error: No session selected for editing.")
                    }
            }
        }
    }
}
