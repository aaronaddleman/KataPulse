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
                if trainingSessions.isEmpty {
                    Text("No training sessions available.")
                        .font(.headline)
                        .padding()
                } else {
                    if dataManager.shouldRefresh {
                        TrainingSessionList(
                            selectedSession: $selectedSession,
                            showEditView: $showEditView
                        )
                        .environmentObject(dataManager)
                    }
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
            .sheet(isPresented: $showCreateView) {
                CreateTrainingSessionView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showEditView) {
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
