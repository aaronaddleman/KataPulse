//
//  StartTrainingView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import AVFoundation

struct StartTrainingView: View {
    let session: TrainingSession
    @State private var currentTechniques: [Technique] = []
    @State var currentStep = 0
    @State var countdown: Int = 10
    @State var timerActive = false
    @State var sessionComplete = false

    private var speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack {
            if sessionComplete {
                Text("Congratulations! You have finished your training session.")
                    .font(.largeTitle)
                    .padding()
            } else {
                Text(currentItem) // Display the current technique, exercise, or kata
                    .font(.largeTitle)
                    .padding()

                ProgressView(value: Double(countdown), total: Double(itemCountdown))
                    .padding()

                Text("Time Remaining: \(countdown)")
                    .font(.headline)
                    .padding()

                if isExercise {
                    Button("Next Exercise") {
                        advanceToNextStep()
                    }
                    .font(.title)
                    .padding()
                } else {
                    Button("Start Timer") {
                        startCountdown()
                    }
                    .font(.title)
                    .padding()
                    .disabled(timerActive)
                }
            }
        }
        .navigationTitle("Training Session")
        .onAppear {
            initializeTechniques() // Initialize techniques when the view appears
            startInitialCountdown()
        }
        .onReceive(timerPublisher) { _ in
            if countdown > 0 && timerActive {
                countdown -= 1
            } else if countdown == 0 {
                advanceToNextStep()
            }
        }
    }

    // Initialize techniques from the session and shuffle if needed
    private func initializeTechniques() {
        currentTechniques = session.techniques // Start with the session's techniques
        if session.randomizeTechniques {
            currentTechniques.shuffle()
        }
    }

    // Announce and start the initial countdown
    private func startInitialCountdown() {
        announcePhrase("Square Horse Weapon Sheath")
        countdown = 10
        timerActive = true
    }

    // The current item (technique, exercise, kata) based on the current step
    private var currentItem: String {
        if currentStep < currentTechniques.count {
            return currentTechniques[currentStep].name
        } else if currentStep - currentTechniques.count < session.exercises.count {
            return session.exercises[currentStep - currentTechniques.count].name
        } else if currentStep - currentTechniques.count - session.exercises.count < session.katas.count {
            return session.katas[currentStep - currentTechniques.count - session.exercises.count].name
        } else {
            return "No more items"
        }
    }

    // Check if the current item is an exercise
    private var isExercise: Bool {
        if currentStep < currentTechniques.count {
            return false
        } else if currentStep < currentTechniques.count + session.exercises.count {
            return true
        } else {
            return false
        }
    }

    // Duration for the current item's countdown timer
    private var itemCountdown: Int {
        if currentStep < currentTechniques.count {
            return currentTechniques[currentStep].timeToComplete
        } else if currentStep < currentTechniques.count + session.exercises.count {
            return 10 // Example time for exercises (manually advanced)
        } else {
            return 30 // Example time for katas
        }
    }

    // Start the countdown timer for the current technique
    private func startCountdown() {
        countdown = itemCountdown
        timerActive = true
        announceCurrentItem()
    }

    // Advance to the next step in the training session
    private func advanceToNextStep() {
        timerActive = false
        if currentStep < currentTechniques.count + session.exercises.count + session.katas.count - 1 {
            currentStep += 1
            startCountdown() // Start the countdown for the next step
        } else {
            sessionComplete = true
            announcePhrase("Congratulations! You have finished your training session.")
        }
    }

    // Announce the current item using text-to-speech
    private func announceCurrentItem() {
        let utterance = AVSpeechUtterance(string: currentItem)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    // Announce a custom phrase using text-to-speech
    private func announcePhrase(_ phrase: String) {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    // Timer publisher for the countdown
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
}
