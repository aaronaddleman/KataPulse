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
        VStack {
            // Debugging log for all sessions
            Text("Loaded \(dataManager.trainingSessions.count) sessions")
                .font(.caption)
                .foregroundColor(.gray)

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
                        Button {
                            dataManager.fetchTrainingSessions()
                            selectedSession = session
                            showEditView = true
                            print("Editing session: \(session.name ?? "Unnamed Session")")
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)

                        Button {
                            dataManager.fetchTrainingSessions()
                            sessionForCalibration = session
                            if sessionForCalibration != nil {
                                showCalibrationView = true
                                print("Calibrating session: \(sessionForCalibration?.name ?? "Unnamed Session")")
                            } else {
                                print("Error: sessionForCalibration is nil after being set.")
                            }
                        } label: {
                            Label("Calibrate", systemImage: "mic")
                        }
                        .tint(.green)

                    }
                    
                    .swipeActions(edge: .leading) { // Move Delete to left swipe
                        Button(role: .destructive) {
                            dataManager.deleteTrainingSession(session: session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .sheet(isPresented: $showCalibrationView) {
            if let session = sessionForCalibration {
                CalibrationView(session: session)
                    .onAppear {
                        print("Presenting CalibrationView for session: \(session.name ?? "Unnamed Session")")
                        if let techniques = session.selectedTechniques?.allObjects as? [TechniqueEntity] {
                            print("Techniques for session: \(techniques.map { $0.name ?? "Unnamed Technique" })")
                        } else {
                            print("No techniques available for session.")
                        }
                    }
            } else {
                Text("No session selected for calibration.")
            }
        }


    }
}
