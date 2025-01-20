//
//  ContentViewSessionsTab.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct SessionsTab: View {
    let trainingSessions: FetchedResults<TrainingSessionEntity>
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
                    TrainingSessionList(
                        trainingSessions: trainingSessions,
                        selectedSession: $selectedSession,
                        showEditView: $showEditView
                    )
                }
            }
            .navigationTitle("Training Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateView) {
                CreateTrainingSessionView()
            }
            .sheet(isPresented: $showEditView) {
                if let selectedSession = selectedSession {
                    CreateTrainingSessionView(editingSession: selectedSession)
                }
            }
        }
    }
}
