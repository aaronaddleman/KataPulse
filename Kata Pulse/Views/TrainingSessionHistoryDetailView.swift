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
                // Session Information
                Text("Session: \(historySession.sessionName)")
                    .font(.title)
                Text("Date: \(formattedDate(historySession.timestamp))")
                    .font(.headline)
                
                // Section 1: All Session Items
                Text("Session Items:")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(historySession.items, id: \.id) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(item.exerciseName)")
                                .font(.body)
                            Text("Time Taken: \(item.timeTaken, specifier: "%.1f") seconds")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Section 2: Known and Not Known Techniques
                Text("Techniques Overview:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Known Techniques
                    Text("Known Techniques")
                        .font(.subheadline)
                        .bold()
                    if knownTechniques().isEmpty {
                        Text("No known techniques.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(knownTechniques(), id: \.id) { item in
                            Text("• \(item.exerciseName)")
                                .font(.body)
                        }
                    }

                    // Not Known Techniques
                    Text("Not Known Techniques")
                        .font(.subheadline)
                        .bold()
                        .padding(.top)
                    if unknownTechniques().isEmpty {
                        Text("No unknown techniques.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(unknownTechniques(), id: \.id) { item in
                            Text("• \(item.exerciseName)")
                                .font(.body)
                        }
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Session Details")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let formattedDate = formatter.string(from: date)
        print("Formatted Date: \(formattedDate)")
        return formattedDate
    }

    // Filter functions for known and unknown techniques
    private func knownTechniques() -> [TrainingSessionHistoryItem] {
        historySession.items.filter { $0.isKnown }
    }

    private func unknownTechniques() -> [TrainingSessionHistoryItem] {
        historySession.items.filter { !$0.isKnown }
    }
}

