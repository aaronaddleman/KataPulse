//
//  ContentViewTrainingSessionList.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

//
//  ContentViewTrainingSessionList.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct TrainingSessionList: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedSession: TrainingSessionEntity?
    @Binding var showEditView: Bool
    @State private var showCalibrationView: Bool = false
    @State private var sessionForCalibration: TrainingSessionEntity?
    let trainingSessions: [TrainingSessionEntity]
    

    var body: some View {
        List {
            ForEach(dataManager.trainingSessions, id: \.self) { session in
                NavigationLink(
                    destination: StartTrainingView(
                        session: convertToTrainingSession(from: session),
                        currentPracticeType: {
                                    if let practiceTypeString = session.practiceType,
                                       let practiceType = PracticeType(rawValue: practiceTypeString) {
                                        return practiceType
                                    } else {
                                        return .soundOff
                                    }
                                }()
                    )
                ) {
                    TrainingSessionRow(session: session)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        dataManager.deleteTrainingSession(session: session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        // Refresh all training sessions
                        dataManager.fetchTrainingSessions()
                        
                        // Select the session directly from the list of all sessions
                        if let fetchedSession = dataManager.trainingSessions.first(where: { $0.id == session.id }) {
                            selectedSession = fetchedSession
                            print("Selected session from refreshed list: \(fetchedSession.name ?? "Unnamed")")
                        } else {
                            // Fallback to the session passed in the ForEach loop
                            selectedSession = session
                            print("Using session from list as fallback: \(session.name ?? "Unnamed Session")")
                        }
                        
                        // Show the edit view
                        showEditView = true
                        print("showEditView is set to true")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)

                    Button {
                        sessionForCalibration = session
                        showCalibrationView = true
                    } label: {
                        Label("Calibrate", systemImage: "mic")
                    }
                    .tint(.green)
                }
            }
        }
        .listStyle(PlainListStyle())
        .sheet(isPresented: $showCalibrationView) {
            if let session = sessionForCalibration {
                CalibrationView(session: session)
            }
        }
    }
}
