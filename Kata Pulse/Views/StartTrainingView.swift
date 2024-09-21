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
    @State var currentTechniques: [Technique] = []
    @State var currentExercises: [Exercise] = []
    @State var currentKatas: [Kata] = []
    @State var currentStep = 0
    @State var countdown: Int = 10
    @State var timerActive = false
    @State var sessionComplete = false
    @State var isInitialGreeting = true // To track the initial greeting

    var speechSynthesizer = AVSpeechSynthesizer()
    var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if sessionComplete {
                Text("Congratulations! You have finished your training session.")
                    .font(.largeTitle)
                    .padding()
            } else if isInitialGreeting {
                Text("Square Horse Weapon Sheath")
                    .font(.largeTitle)
                    .padding()

                ProgressView(value: Double(countdown), total: 10)
                    .padding()

                Text("Time Remaining: \(countdown)")
                    .font(.headline)
                    .padding()

                Button(timerActive ? "Stop Timer" : "Start Timer") {
                    if timerActive {
                        stopCountdown()
                    } else {
                        startCountdown(for: "Square Horse Weapon Sheath", countdown: 10)
                    }
                }
                .font(.title)
                .padding()
            } else {
                Text(currentItem)
                    .font(.largeTitle)
                    .padding()

                ProgressView(value: Double(countdown), total: Double(itemCountdown))
                    .padding()

                Text("Time Remaining: \(countdown)")
                    .font(.headline)
                    .padding()

                if isExercise {
                    // Show buttons for exercises (manual control)
                    Button("Next Exercise") {
                        advanceToNextStep()
                    }
                    .font(.title)
                    .padding()

                    Button(timerActive ? "Stop Timer" : "Start Timer") {
                        if timerActive {
                            stopCountdown()
                        } else {
                            startCountdown(for: currentItem, countdown: countdown) // Resume where it left off
                        }
                    }
                    .font(.title)
                    .padding()

                } else if isKata {
                    // Show buttons for katas (manual control)
                    Button("Next Kata") {
                        advanceToNextStep()
                    }
                    .font(.title)
                    .padding()

                    Button(timerActive ? "Stop Timer" : "Start Timer") {
                        if timerActive {
                            stopCountdown()
                        } else {
                            startCountdown(for: currentItem, countdown: countdown) // Resume where it left off
                        }
                    }
                    .font(.title)
                    .padding()

                } else {
                    // For techniques, the timer is automatically controlled
                    Button(timerActive ? "Stop Timer" : "Start Timer") {
                        if timerActive {
                            stopCountdown()
                        } else {
                            startCountdown(for: currentItem, countdown: countdown) // Resume where it left off
                        }
                    }
                    .font(.title)
                    .padding()
                }
            }
        }
        .navigationTitle("Training Session")
        .onAppear {
            setupTrainingSession()
            if isInitialGreeting {
                startCountdown(for: "Square Horse Weapon Sheath", countdown: 10)
            } else {
                announceCurrentItem()
                startCountdown(for: currentItem, countdown: itemCountdown)
            }
        }
        .onDisappear {
            endTrainingSession() // Stop all training sessions when exiting
        }
        .onReceive(timerPublisher) { _ in
            if countdown > 0 && timerActive {
                countdown -= 1
            } else if countdown == 0 && !sessionComplete {
                if isInitialGreeting {
                    isInitialGreeting = false
                    startCountdown(for: currentItem, countdown: itemCountdown)
                } else {
                    advanceToNextStep()
                }
            }
        }
    }

    // The current item (technique, exercise, kata) based on the current step, returns a string for the item's name
    private var currentItem: String {
        if currentStep < currentTechniques.count {
            return currentTechniques[currentStep].name
        } else if currentStep - currentTechniques.count < currentExercises.count {
            return currentExercises[currentStep - currentTechniques.count].name
        } else if currentStep - currentTechniques.count - currentExercises.count < currentKatas.count {
            return currentKatas[currentStep - currentTechniques.count - currentExercises.count].name
        } else {
            return "No more items"
        }
    }
    
    // Check if the current item is an exercise (manually advance)
    private var isExercise: Bool {
        if currentStep < currentTechniques.count {
            return false
        } else if currentStep < currentTechniques.count + currentExercises.count {
            return true
        } else {
            return false
        }
    }
    
    private var isKata: Bool {
        if currentStep >= currentTechniques.count + currentExercises.count && currentStep < currentTechniques.count + currentExercises.count + currentKatas.count {
            return true
        }
        return false
    }

    // Duration for the current item's countdown timer
    private var itemCountdown: Int {
        if currentStep < currentTechniques.count {
            return currentTechniques[currentStep].timeToComplete
        } else if currentStep < currentTechniques.count + currentExercises.count {
            return 10 // Example time for exercises (manually advanced)
        } else {
            return 30 // Example time for katas
        }
    }
    
    // Shuffle techniques if randomization is enabled and set up the session
    private func setupTrainingSession() {
        // Set up techniques
        currentTechniques = session.techniques
        if session.randomizeTechniques {
            currentTechniques.shuffle()
        }

        // Set up exercises and katas
        currentExercises = session.exercises
        currentKatas = session.katas
    }
    
    private func startCountdown(for item: String, countdown: Int) {
        self.countdown = countdown
        timerActive = true
        announce(item)
    }

    private func stopCountdown() {
        timerActive = false
    }

    private func advanceToNextStep() {
        timerActive = false
        if currentStep < currentTechniques.count + currentExercises.count + currentKatas.count - 1 {
            currentStep += 1
            startCountdown(for: currentItem, countdown: itemCountdown) // Automatically start the countdown for the next item
        } else {
            sessionComplete = true
            announce("Congratulations! You have finished your training session.")
        }
    }

    private func announce(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    private func announceCurrentItem() {
        announce(currentItem)
    }

    private func endTrainingSession() {
        timerActive = false
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
