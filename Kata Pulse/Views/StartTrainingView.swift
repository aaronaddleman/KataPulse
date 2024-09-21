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
    @State var currentBlocks: [Block] = [] // New
    @State var currentStrikes: [Strike] = [] // New
    @State var currentStep = 0
    @State var countdown: Int = 2 // Updated to 2 seconds between blocks/strikes
    @State var timerActive = false
    @State var sessionComplete = false
    @State var isInitialGreeting = true
    @State var currentRepetition = 1 // Track the repetition count for blocks/strikes
    @State var isLeftSide = true // Track whether it's left or right side for blocks/strikes

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

                if isBlockOrStrike {
                    // For blocks and strikes, we count the reps and alternate sides
                    Text("Repetition \(currentRepetition) on \(isLeftSide ? "Left" : "Right") side")
                        .font(.headline)
                        .padding()

                    Button(timerActive ? "Stop Timer" : "Start Timer") {
                        if timerActive {
                            stopCountdown()
                        } else {
                            startCountdown(for: currentItem, countdown: countdown)
                        }
                    }
                    .font(.title)
                    .padding()
                } else {
                    // Other item types (techniques, exercises, katas)
                    Button(timerActive ? "Stop Timer" : "Start Timer") {
                        if timerActive {
                            stopCountdown()
                        } else {
                            startCountdown(for: currentItem, countdown: countdown)
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
            endTrainingSession()
        }
        .onReceive(timerPublisher) { _ in
            if countdown > 0 && timerActive {
                countdown -= 1
            } else if countdown == 0 && !sessionComplete {
                if isInitialGreeting {
                    isInitialGreeting = false
                    startCountdown(for: currentItem, countdown: itemCountdown)
                } else if isBlockOrStrike {
                    // Handle block/strike repetitions
                    if currentRepetition < 10 {
                        currentRepetition += 1
                    } else {
                        currentRepetition = 1
                        isLeftSide.toggle() // Alternate sides
                        advanceToNextStep()
                    }
                } else {
                    advanceToNextStep()
                }
            }
        }
    }

    // The current item (technique, exercise, kata, block, strike) based on the current step
    private var currentItem: String {
        if currentStep < currentTechniques.count {
            return currentTechniques[currentStep].name
        } else if currentStep - currentTechniques.count < currentExercises.count {
            return currentExercises[currentStep - currentTechniques.count].name
        } else if currentStep - currentTechniques.count - currentExercises.count < currentKatas.count {
            return currentKatas[currentStep - currentTechniques.count - currentExercises.count].name
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count < currentBlocks.count {
            return "Block \(isLeftSide ? "Left" : "Right")"
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentBlocks.count < currentStrikes.count {
            return "Strike \(isLeftSide ? "Left" : "Right")"
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

    private var isBlockOrStrike: Bool {
        return currentStep >= currentTechniques.count + currentExercises.count + currentKatas.count &&
               currentStep < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count
    }
    
    // Shuffle techniques if randomization is enabled and set up the session
    // Setup blocks and strikes
    private func setupTrainingSession() {
        currentTechniques = session.techniques
        if session.randomizeTechniques {
            currentTechniques.shuffle()
        }
        currentExercises = session.exercises
        currentKatas = session.katas
        currentBlocks = session.blocks // Setup blocks
        currentStrikes = session.strikes // Setup strikes
    }
    
    private func startCountdown(for item: String, countdown: Int) {
        self.countdown = countdown
        timerActive = true
        announce(item)
    }

    private func stopCountdown() {
        timerActive = false
    }

    // Advance to the next step after 10 reps for blocks and strikes
    private func advanceToNextStep() {
        timerActive = false
        if currentStep < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count - 1 {
            currentStep += 1
            currentRepetition = 1 // Reset the repetition for blocks/strikes
            startCountdown(for: currentItem, countdown: itemCountdown)
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
