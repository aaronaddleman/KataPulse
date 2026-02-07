//
//  MotionDetectionView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 7/4/25.
//

import SwiftUI

struct MotionDetectionView: View {
    @StateObject private var motionDetector = MotionDetector()
    @State private var repetitionTracker: RepetitionTracker
    
    let exerciseName: String
    let onComplete: () -> Void
    
    init(exerciseName: String, totalReps: Int, onComplete: @escaping () -> Void) {
        self.exerciseName = exerciseName
        self.onComplete = onComplete
        self._repetitionTracker = State(initialValue: RepetitionTracker(totalReps: totalReps))
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            Text("Motion Detection Active")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Motion intensity indicator
            VStack(spacing: 10) {
                Text("Motion Intensity")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(motionDetector.isMoving ? Color.red : Color.blue)
                            .frame(width: CGFloat(motionDetector.motionIntensity * 100), height: 20)
                            .animation(.easeInOut(duration: 0.1), value: motionDetector.motionIntensity)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text(motionDetector.isMoving ? "Moving" : "Still")
                    .font(.caption)
                    .foregroundColor(motionDetector.isMoving ? .red : .blue)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            // Repetition progress
            RepetitionProgressView(
                tracker: repetitionTracker,
                exerciseName: exerciseName,
                onTapComplete: {
                    handleRepetitionComplete()
                },
                onSkip: {
                    if repetitionTracker.isComplete {
                        onComplete()
                    } else {
                        // Skip to next exercise
                        repetitionTracker.currentRep = repetitionTracker.totalReps
                        onComplete()
                    }
                }
            )
            
            // Motion detection controls
            VStack(spacing: 15) {
                Text("Motion Detection")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button(action: {
                        if motionDetector.isDetectingMotion {
                            motionDetector.stopDetection()
                        } else {
                            motionDetector.startDetection()
                        }
                    }) {
                        Label(
                            motionDetector.isDetectingMotion ? "Stop Detection" : "Start Detection",
                            systemImage: motionDetector.isDetectingMotion ? "pause.circle.fill" : "play.circle.fill"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(motionDetector.isDetectingMotion ? Color.red : Color.green)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            setupMotionDetection()
        }
        .onDisappear {
            motionDetector.stopDetection()
        }
    }
    
    private func setupMotionDetection() {
        motionDetector.onRepetitionComplete = {
            handleRepetitionComplete()
        }
    }
    
    private func handleRepetitionComplete() {
        repetitionTracker.incrementRep()
        
        if repetitionTracker.isComplete {
            motionDetector.stopDetection()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
        }
    }
}

struct MotionDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        MotionDetectionView(
            exerciseName: "Push-ups",
            totalReps: 10,
            onComplete: {}
        )
    }
}