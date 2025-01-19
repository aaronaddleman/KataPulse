//
//  ContentViewTrainingSessionRow.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI

struct TrainingSessionRow: View {
    let session: TrainingSessionEntity

    var body: some View {
        VStack(alignment: .leading) {
            Text(session.name ?? "Unnamed Session")
                .font(.headline)
                .padding(.vertical, 2)

            // Display the counts for each category
            Text("Techniques: \(session.selectedTechniques?.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Exercises: \(session.selectedExercises?.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Katas: \(session.selectedKatas?.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Blocks: \(session.selectedBlocks?.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Strikes: \(session.selectedStrikes?.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Kicks: \(session.selectedKicks?.count ?? 0)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
