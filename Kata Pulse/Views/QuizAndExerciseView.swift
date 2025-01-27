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
    @AppStorage("quizTestingMode") private var quizTestingMode: String = "simple"

    let session: TrainingSession
    @StateObject private var speechManager = SpeechRecognizerManager()

    @State private var currentTechniques: [String] = []
    @State private var currentTechnique: String?
    @State private var showExercise: Bool = false
    
    @State private var isListening: Bool = false
    @State private var recognizedText: String = ""
    @State private var testResult: String = ""

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

                Text("Recognized: \(recognizedText)")
                    .font(.body)
                    .foregroundColor(.blue)
                    .padding()

                Text("Test Result: \(testResult)")
                    .font(.headline)
                    .foregroundColor(testResult == "Match Found!" ? .green : .red)
                    .padding()

                Button(isListening ? "Stop Listening" : "Start Listening") {
                    if isListening {
                        stopListening()
                    } else {
                        startListening()
                    }
                }
            }
        }
        .onDisappear {
            speechManager.stopListening()
        }
    }
    
    private func startListening() {
        guard !speechManager.isAudioEngineRunning else {
            print("Audio engine is already running.")
            return
        }

        isListening = true
        recognizedText = "" // Clear previous text
        speechManager.startListening { result, isFinal in
            recognizedText = result
            
            if isFinal {
                validateText(result) // Validate only on the final result
            }
        }

    }
    
    private func stopListening() {
        isListening = false
        speechManager.stopListening()
    }
    
    // MARK: - Validate Text
    private func validateText(_ text: String) {
        let techniques = session.techniques
        let matchingMode = quizTestingMode // Read from AppStorage

        let match: Bool
        if matchingMode == "simple" {
            match = techniques.contains { $0.name.lowercased() == text.lowercased() || $0.aliases.contains { $0.lowercased() == text.lowercased() } }
        } else {
            match = techniques.contains { technique in
                let distances = [technique.name] + technique.aliases
                return distances.contains { alias in
                    levenshteinDistance(alias.lowercased(), text.lowercased()) <= 2 // Fuzzy match threshold
                }
            }
        }

        testResult = match ? "Match Found!" : "No Match Found!"
    }

}
