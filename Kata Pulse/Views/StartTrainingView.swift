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
    @State var countdown: Int = 10 // Reset for a simpler countdown
    @State var timerActive = false
    @State var sessionComplete = false
    @State var isInitialGreeting = true

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
            
            // "Next Item" button at the bottom of all items
            Button("Next Item") {
                advanceToNextStep() // Manually advance to the next item
            }
            .font(.title)
            .padding()
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

    // The current item (technique, exercise, kata, block, strike) based on the current step
    private var currentItem: String {
        if currentStep < currentTechniques.count {
            return currentTechniques[currentStep].name
        } else if currentStep - currentTechniques.count < currentExercises.count {
            return currentExercises[currentStep - currentTechniques.count].name
        } else if currentStep - currentTechniques.count - currentExercises.count < currentKatas.count {
            return currentKatas[currentStep - currentTechniques.count - currentExercises.count].name
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count < currentBlocks.count {
            return currentBlocks[currentStep - currentTechniques.count - currentExercises.count - currentKatas.count].name // Just name of block
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentBlocks.count < currentStrikes.count {
            return currentStrikes[currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentBlocks.count].name // Just name of strike
        } else {
            return "No more items"
        }
    }

    private var isBlockOrStrike: Bool {
        return currentStep >= currentTechniques.count + currentExercises.count + currentKatas.count &&
               currentStep < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count
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
    
    // Setup techniques, exercises, katas, blocks, and strikes
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
        announce(item) // Announce the name of the item
    }

    private func stopCountdown() {
        timerActive = false
    }

    private func advanceToNextStep() {
        timerActive = false
        if currentStep < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count - 1 {
            currentStep += 1
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
