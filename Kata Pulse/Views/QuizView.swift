//
//  QuizView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/19/25.
//

import SwiftUI
import Speech
import AVFoundation
import os.log

struct QuizView: View {
    let session: TrainingSession

    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var currentTechniques: [String] = []
    @State private var correctCount: Int = 0
    @State private var wrongCount: Int = 0
    @State private var missedTechniques: [String] = []
    
    private let logger = Logger(subsystem: "com.example.KataPulse", category: "QuizView")

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
        // Stop any existing recognition task
        if let recognitionTask = speechManager.recognitionTask {
            recognitionTask.cancel()
            speechManager.recognitionTask = nil
        }

        // Stop and reset the audio engine if it's running
        if speechManager.audioEngine.isRunning {
            speechManager.audioEngine.stop()
            speechManager.audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Configure the audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Audio session configuration failed: \(error.localizedDescription)")
            return
        }

        logger.log("Starting to listen. Techniques being evaluated: \(currentTechniques.joined(separator: ", "))")

        // Start a new recognition task
        speechManager.startListening(matching: currentTechniques, onResult: { (recognizedText: String) in
            logger.log("Recognized text: \(recognizedText)")

            if recognizedText.isEmpty {
                logger.error("No speech detected. Retrying...")
                self.retryRecognition(after: 2)
            } else {
                self.handleMatch(recognizedText)
                // Restart listening for the next input after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startListening()
                }
            }
        })
    }


    func retryRecognition(after delay: TimeInterval) {
        logger.log("Retrying speech recognition after \(delay) seconds.")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.startListening()
        }
    }


    func handleMatch(_ recognizedText: String) {
        print("Handling match for recognized text: \(recognizedText)")
        
        // Find the closest match
        if let closestMatch = findClosestMatch(for: recognizedText, in: predefinedTechniques) {
            print("Matched technique: \(closestMatch.name)")
            correctCount += 1
            currentTechniques.removeAll { $0 == closestMatch.name }
        } else {
            print("No close match found for: \(recognizedText)")
            wrongCount += 1
        }

        // Check if all techniques are completed
        if currentTechniques.isEmpty {
            missedTechniques = currentTechniques
            print("Quiz complete! Missed techniques: \(missedTechniques.joined(separator: ", "))")
            speechManager.stopListening()
        }
    }

    // Helper function to find the closest match using Levenshtein distance
    func findClosestMatch(for input: String, in techniques: [Technique]) -> Technique? {
        let threshold = 5 // Increased allowable distance
        var closestMatch: Technique? = nil
        var smallestDistance = Int.max

        for technique in techniques {
            // Check technique name
            let nameDistance = levenshteinDistance(input.lowercased(), technique.name.lowercased())
            if nameDistance < smallestDistance && nameDistance <= threshold {
                smallestDistance = nameDistance
                closestMatch = technique
            }

            // Check aliases
            for alias in technique.aliases {
                let aliasDistance = levenshteinDistance(input.lowercased(), alias.lowercased())
                if aliasDistance < smallestDistance && aliasDistance <= threshold {
                    smallestDistance = aliasDistance
                    closestMatch = technique
                }
            }
        }

        if let match = closestMatch {
            print("Closest match found: \(match.name)")
        } else {
            print("No match found for input: \(input)")
        }

        return closestMatch
    }


}
