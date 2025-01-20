//
//  QuizAndExerciseView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI
import Speech
import AVFoundation

struct QuizAndExerciseView: View {
    let session: TrainingSession
    @StateObject private var speechManager = SpeechRecognizerManager()

    @State private var currentTechniques: [String] = []
    @State private var currentTechnique: String?
    @State private var showExercise: Bool = false

    var body: some View {
        VStack {
            if showExercise, let currentTechnique = currentTechnique {
                Text("Perform Exercise for \(currentTechnique)")
                    .font(.largeTitle)
                    .padding()

                Button("Next Technique") {
                    showExercise = false
                    self.currentTechnique = nil
                }
                .font(.title2)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Text("Say the name of a technique")
                    .font(.largeTitle)
                    .padding()

                if speechManager.isListening {
                    Text("Listening...")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                } else {
                    Text("Recognized: \(speechManager.recognizedText)")
                        .font(.headline)
                        .padding()
                }

                Button(speechManager.isListening ? "Stop Listening" : "Start Listening") {
                    if speechManager.isListening {
                        speechManager.stopListening()
                    } else {
                        speechManager.startListening(matching: currentTechniques)
                    }
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .onAppear {
            currentTechniques = session.techniques.map { $0.name }
            speechManager.requestSpeechAuthorization()
            speechManager.onMatch = { technique in
                self.currentTechnique = technique
                self.showExercise = true
            }
        }
        .onDisappear {
            speechManager.stopListening()
        }
    }
}
