//
//  ContentViewTrainingSessionList.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct TrainingSessionList: View {
    let trainingSessions: FetchedResults<TrainingSessionEntity>
    @Binding var selectedSession: TrainingSessionEntity?
    @Binding var showEditView: Bool

    var body: some View {
        List {
            ForEach(trainingSessions, id: \.self) { session in
                NavigationLink(
                    destination: StartTrainingView(
                        session: convertToTrainingSession(from: session),
                        currentPracticeType: PracticeType(rawValue: session.practiceType ?? "") ?? .soundOff
                    )
                ) {
                    TrainingSessionRow(session: session)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteSession(session: session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        selectedSession = session
                        showEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private func deleteSession(session: TrainingSessionEntity) {
        // Your delete logic here
    }
}
