//
//  TrainingSessionHistoryView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/6/24.
//

import SwiftUI
import CoreData

struct TrainingSessionHistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: TrainingSessionHistoryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrainingSessionHistoryEntity.timestamp, ascending: false)]
    ) private var historySessions: FetchedResults<TrainingSessionHistoryEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(historySessions, id: \.self) { session in
                    NavigationLink(
                        destination: TrainingSessionHistoryDetailView(historySession: convertToTrainingSessionHistory(from: session))
                    ) {
                        VStack(alignment: .leading) {
                            Text(session.sessionName ?? "Unnamed Session")
                                .font(.headline)
                            Text("Date: \(formattedDate(session.timestamp ?? Date()))")
                                .font(.subheadline)
                        }
                    }
                }
                .onDelete(perform: deleteHistorySession)
            }
            .navigationTitle("Training History")
            .toolbar {
                EditButton()
            }
        }
    }

    // Helper function to format the date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Function to handle the deletion of history sessions
    private func deleteHistorySession(at offsets: IndexSet) {
        for index in offsets {
            let session = historySessions[index]
            context.delete(session)
        }
        do {
            try context.save()
        } catch {
            print("Failed to delete history session: \(error.localizedDescription)")
        }
    }

    // Helper function to convert Core Data entity to TrainingSessionHistory model
    private func convertToTrainingSessionHistory(from entity: TrainingSessionHistoryEntity) -> TrainingSessionHistory {
        let historyItems = (entity.items as? Set<TrainingSessionHistoryItemsEntity>)?.map { TrainingSessionHistoryItem(from: $0) } ?? []
        return TrainingSessionHistory(
            id: entity.id ?? UUID(),
            sessionName: entity.sessionName ?? "Unnamed Session",
            timestamp: entity.timestamp ?? Date(), // Change 'date' to 'timestamp'
            items: historyItems
        )
    }
}
