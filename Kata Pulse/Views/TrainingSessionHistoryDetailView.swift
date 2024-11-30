//
//  TrainingSessionHistoryDetailView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/6/24.
//

import SwiftUI
import CoreData

struct TrainingSessionHistoryDetailView: View {
    let historySession: TrainingSessionHistory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Session: \(historySession.sessionName)")
                    .font(.title)
                Text("Date: \(formattedDate(historySession.timestamp))")
                    .font(.headline)
                
                Text("Session Items:")
                    .font(.headline)
                
                ForEach(historySession.items, id: \.self) { item in
                    Text("\(item.exerciseName): \(item.timeTaken) seconds")
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("Session Details")
        .onAppear {
            // Logging to check the session is being loaded properly
            print("Session loaded for details: \(historySession.sessionName)")
            print("Session timestamp: \(historySession.timestamp)")
            print("Items count: \(historySession.items.count)")
            
            for item in historySession.items {
                print("Item: \(item.exerciseName), Time Taken: \(item.timeTaken)")
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
