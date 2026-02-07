//
//  RepetitionProgressView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 7/4/25.
//

import SwiftUI

struct RepetitionProgressView: View {
    let tracker: RepetitionTracker
    let exerciseName: String
    let onTapComplete: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Exercise name
            Text(exerciseName)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0.0, to: tracker.progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: tracker.progress)
                
                VStack {
                    Text("\(tracker.currentRep)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("of \(tracker.totalReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status text
            if tracker.isComplete {
                Text("Exercise Complete!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            } else {
                Text("Complete repetition then tap or wait for detection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                if !tracker.isComplete {
                    Button(action: onTapComplete) {
                        Label("Rep Complete", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                Button(action: onSkip) {
                    Label(tracker.isComplete ? "Next Exercise" : "Skip", systemImage: "arrow.right.circle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tracker.isComplete ? Color.green : Color.orange)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct RepetitionProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RepetitionProgressView(
                tracker: RepetitionTracker(totalReps: 10),
                exerciseName: "Push-ups",
                onTapComplete: {},
                onSkip: {}
            )
            .previewDisplayName("Starting")
            
            RepetitionProgressView(
                tracker: {
                    var tracker = RepetitionTracker(totalReps: 10)
                    tracker.currentRep = 7
                    return tracker
                }(),
                exerciseName: "Burpees",
                onTapComplete: {},
                onSkip: {}
            )
            .previewDisplayName("In Progress")
            
            RepetitionProgressView(
                tracker: {
                    var tracker = RepetitionTracker(totalReps: 10)
                    tracker.currentRep = 10
                    return tracker
                }(),
                exerciseName: "Squats",
                onTapComplete: {},
                onSkip: {}
            )
            .previewDisplayName("Complete")
        }
    }
}