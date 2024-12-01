//
//  CountingStatisticsView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 11/30/24.
//

import SwiftUI
import CoreData

struct CountingStatisticsView: View {
    @FetchRequest(
        entity: TrainingSessionHistoryItemsEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrainingSessionHistoryItemsEntity.exerciseName, ascending: true)]
    ) private var historyItems: FetchedResults<TrainingSessionHistoryItemsEntity>

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Techniques Count")) {
                    if historyItems.isEmpty {
                        Text("No history found.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(techniqueCounts.keys.sorted(), id: \.self) { techniqueName in
                            HStack {
                                Text(techniqueName)
                                Spacer()
                                Text("\(techniqueCounts[techniqueName] ?? 0)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Counting Statistics")
        }
    }

    /// Helper to calculate counts for each technique
    private var techniqueCounts: [String: Int] {
        var counts = [String: Int]()
        for item in historyItems {
            let name = item.exerciseName ?? "Unnamed Technique"
            counts[name, default: 0] += 1
        }
        return counts
    }
}

