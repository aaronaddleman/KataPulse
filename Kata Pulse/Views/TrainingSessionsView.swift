//
//  TrainingSessionsView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import CoreData

struct TrainingSessionsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: TrainingSessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrainingSessionEntity.name, ascending: true)]
    ) var trainingSessions: FetchedResults<TrainingSessionEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(trainingSessions, id: \.self) { sessionEntity in
                    NavigationLink(
                        destination: StartTrainingView(
                            session: convertToTrainingSession(
                                from: sessionEntity
                            )
                        )
                    ) {
                        Text(sessionEntity.name ?? "Unnamed")
                    }
                }
            }
            .navigationTitle("Training Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateTrainingSessionView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
