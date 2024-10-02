//
//  StartTrainingView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import AVFoundation
import CoreData

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
    @State var initialGreetingDone = false // Added to track greeting completion

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
            if isInitialGreeting && !initialGreetingDone {
                startCountdown(for: "Square Horse Weapon Sheath", countdown: 10)
            }
        }
        .onDisappear {
            endTrainingSession() // Stop all training sessions when exiting
        }
        .onReceive(timerPublisher) { _ in
            if timerActive && countdown > 0 {
                countdown -= 1
            } else if countdown == 0 && timerActive {
                timerActive = false // Stop the timer

                if isInitialGreeting && !initialGreetingDone {
                    // The greeting is complete, now move to the first technique
                    isInitialGreeting = false
                    initialGreetingDone = true
                    startCountdown(for: currentItem, countdown: itemCountdown)
                } else {
                    // Advance to the next step (technique, exercise, etc.)
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

    private func setupTrainingSession() {
        guard let sessionEntity = fetchTrainingSessionEntity() else {
            print("Error: Could not load the session data from CoreData.")
            sessionComplete = true
            return
        }

        currentTechniques = (sessionEntity.selectedTechniques?.allObjects as? [TechniqueEntity])?.map {
            Technique(
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                beltLevel: $0.beltLevel ?? "Unknown",
                timeToComplete: Int($0.timeToComplete),
                isSelected: $0.isSelected
            )
        } ?? []

        print("Initial loaded techniques (only selected ones):")
        if currentTechniques.isEmpty {
            print("No techniques were loaded from the session.")
        } else {
            for technique in currentTechniques {
                print("Technique: \(technique.name), orderIndex: \(technique.orderIndex), selected: \(technique.isSelected)")
            }
        }

        // Handle the ordering of techniques
        if session.randomizeTechniques {
            currentTechniques.shuffle()
            print("Techniques have been shuffled.")
        } else {
            currentTechniques.sort(by: { $0.orderIndex < $1.orderIndex })
            print("Techniques ordered by orderIndex.")
            for (index, technique) in currentTechniques.enumerated() {
                print("Technique \(index): \(technique.name), orderIndex: \(technique.orderIndex)")
            }
        }

        if !currentTechniques.isEmpty {
            currentStep = 0
        } else {
            print("No techniques found to start training.")
            sessionComplete = true
        }
    }

    // Fetch TrainingSessionEntity from CoreData
    private func fetchTrainingSessionEntity() -> TrainingSessionEntity? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let fetchedSession = results.first {
                print("Successfully fetched session: \(fetchedSession.name ?? "Unnamed Session")")
                return fetchedSession
            } else {
                print("No matching session found in Core Data.")
            }
        } catch {
            print("Error fetching session: \(error)")
        }

        return nil
    }

    private func startCountdown(for item: String, countdown: Int) {
        self.countdown = countdown
        timerActive = true

        if isInitialGreeting {
            announce("Square Horse Weapon Sheath")
        } else {
            announce(item)
        }
    }

    private func stopCountdown() {
        timerActive = false
    }

    private func advanceToNextStep() {
        if currentStep < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count - 1 {
            currentStep += 1
            startCountdown(for: currentItem, countdown: itemCountdown) // Start the countdown for the next item
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
