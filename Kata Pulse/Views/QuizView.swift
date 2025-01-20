//
//  QuizView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI
import Speech
import AVFoundation

struct QuizView: View {
    let session: TrainingSession

    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var currentTechniques: [String] = []
    @State private var correctCount: Int = 0
    @State private var wrongCount: Int = 0
    @State private var missedTechniques: [String] = []

    var body: some View {
        VStack {
            Text("Quiz Mode")
                .font(.largeTitle)
                .padding()

            Text("Say the name of a technique")
                .font(.headline)
                .padding()

            if speechManager.isListening {
                Text("Listening...")
                    .font(.subheadline)
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
                    startListening()
                }
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            VStack {
                Text("Correct: \(correctCount)")
                    .foregroundColor(.green)
                Text("Wrong: \(wrongCount)")
                    .foregroundColor(.red)
                Text("Missed Techniques: \(missedTechniques.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            .padding()
        }
        .onAppear {
            currentTechniques = session.techniques.map { $0.name }
            speechManager.requestSpeechAuthorization()
            speechManager.onMatch = handleMatch
        }
        .onDisappear {
            speechManager.stopListening()
        }
    }

    // MARK: - Matching Logic
    func startListening() {
        speechManager.startListening(matching: currentTechniques)
    }

    func handleMatch(_ technique: String) {
        if currentTechniques.contains(technique) {
            correctCount += 1
            currentTechniques.removeAll { $0 == technique }
        } else {
            wrongCount += 1
        }

        if currentTechniques.isEmpty {
            missedTechniques = currentTechniques
            print("Quiz complete!")
            speechManager.stopListening()
        }
    }
}

