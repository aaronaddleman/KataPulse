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
    @AppStorage("quizTestingMode") private var quizTestingMode: String = "simple"
    @StateObject private var speechManager = SpeechRecognizerManager()

    @State private var isListening: Bool = false
    @State private var recognizedText: String = ""
    @State private var testResult: String = ""
    @State private var guessedTechniques: [String] = []
    @State private var speechAuthorized: Bool = false
    
    let session: TrainingSession

    var body: some View {
        VStack {
            if speechAuthorized {
                Text("Speech recognition is ready!")
                    .foregroundColor(.green)
            } else {
                Text("Speech recognition is not authorized.")
                    .foregroundColor(.red)
            }
            
            Text("Quiz Mode")
                .font(.largeTitle)
                .padding()

            Text("Say the name of a technique")
                .font(.headline)
                .padding()
            
            // Progress Bar
            ProgressView(value: Double(guessedTechniques.count), total: Double(session.techniques.count))
                .padding()
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))


            Text("Recognized: \(recognizedText)")
                .font(.body)
                .foregroundColor(.blue)
                .padding()

            Text("Test Result: \(testResult)")
                .font(.headline)
                .foregroundColor(testResult == "Match Found!" ? .green : .red)
                .padding()
            
            // List of Guessed Techniques
            if !guessedTechniques.isEmpty {
                VStack(alignment: .leading) {
                    Text("Guessed Techniques:")
                        .font(.headline)
                        .padding(.top)

                    ForEach(guessedTechniques, id: \.self) { technique in
                        Text("✔️ \(technique)")
                            .font(.body)
                            .padding(.bottom, 2)
                    }
                }
                .padding()
            }

            Button(isListening ? "Stop Listening" : "Start Listening") {
                if isListening {
                    print("isListening is: \(isListening)")
                    speechManager.stopListening { finalText in
                        if finalText != "No recognized text" {
                            print("User stopped listening. Final recognized text: \(finalText)")
                            validateText(finalText) // Evaluate the final recognized text
                        }
                    }
                    isListening.toggle() // Toggle after stopping
                } else {
                    print("isListening is: \(isListening)")
                    speechManager.startListening { result, isFinal in
                        recognizedText = result

                        if isFinal {
                            print("Final recognized text: \(result)")
                            validateText(result) // Validate only the finalized text
                            speechManager.stopListening() // Stop listening automatically
                            isListening.toggle() // Ensure it reflects the stopped state
                        }
                    }
                    isListening.toggle() // Toggle immediately when starting
                }
            }
            .padding()
            .background(isListening ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)


            Spacer()
        }
        .onAppear {
            requestSpeechRecognitionAuthorization()
        }
        .onDisappear {
            stopListening() // Ensure the audio engine stops when leaving the view
        }
    }
    
    private func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized.")
                    speechAuthorized = true
                case .denied:
                    print("Speech recognition authorization denied.")
                    speechAuthorized = false
                case .restricted:
                    print("Speech recognition restricted on this device.")
                    speechAuthorized = false
                case .notDetermined:
                    print("Speech recognition not determined.")
                    speechAuthorized = false
                @unknown default:
                    print("Unknown authorization status.")
                    speechAuthorized = false
                }
            }
        }
    }

    // MARK: - Start Listening
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
                print("Final recognized text: \(recognizedText)")
                validateText(recognizedText) // Validate only the final result
            }
        }
    }


    // MARK: - Stop Listening
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

        if match {
            // Check if already guessed
            if !guessedTechniques.contains(text) {
                guessedTechniques.append(text)
            }
            testResult = "Match Found!"
        } else {
            testResult = "No Match Found!"
        }
    }

    // MARK: - Levenshtein Distance
    private func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)

        // Handle edge cases
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }

        // Initialize DP matrix
        var dp = [[Int]](repeating: [Int](repeating: 0, count: bChars.count + 1), count: aChars.count + 1)
        for i in 0...aChars.count { dp[i][0] = i }
        for j in 0...bChars.count { dp[0][j] = j }

        // Compute distances
        for i in 1...aChars.count {
            for j in 1...bChars.count {
                if aChars[i - 1] == bChars[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]) + 1
                }
            }
        }
        return dp[aChars.count][bChars.count]
    }


}
