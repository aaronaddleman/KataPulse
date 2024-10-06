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
    @State var currentBlocks: [Block] = []
    @State var currentStrikes: [Strike] = []
    @State var currentKicks: [Kick] = []
    @State var currentStep = 0
    @State var countdown: Int = 10 // Reset for a simpler countdown
    @State var timerActive = false
    @State var sessionComplete = false
    @State var isInitialGreeting = true
    @State var isExercisePause = false // New state to track if we're pausing for an exercise

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
            } else if isExercisePause {
                // Display the current exercise name and button to continue
                Text(currentItem)
                    .font(.largeTitle)
                    .padding()

                Button("Next Exercise") {
                    isExercisePause = false
                    advanceToNextStep() // Manually advance to the next item
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
            if !isExercisePause {
                Button("Next Item") {
                    advanceToNextStep() // Manually advance to the next item
                }
                .font(.title)
                .padding()
            }
        }
        .navigationTitle("Training Session")
        .onAppear {
            setupTrainingSession()
            if isInitialGreeting {
                startCountdown(for: "Square Horse Weapon Sheath", countdown: 10)
            } else {
                announceCurrentItem()
                handleStepWithoutCountdown() // Start by handling the current item based on type
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

                if isInitialGreeting {
                    // The greeting is complete, now move to the first technique
                    isInitialGreeting = false
                    handleStepWithoutCountdown() // Handle the first item after the greeting
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
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count < currentKicks.count {
            return currentKicks[currentStep - currentTechniques.count - currentExercises.count - currentKatas.count].name
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count < currentBlocks.count {
            return currentBlocks[currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count].name
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count - currentBlocks.count < currentStrikes.count {
            return currentStrikes[currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count - currentBlocks.count].name
        } else {
            return "No more items"
        }
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

        // Load and sort techniques
        currentTechniques = (sessionEntity.selectedTechniques?.allObjects as? [TechniqueEntity])?.map {
            Technique(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                beltLevel: $0.beltLevel ?? "Unknown",
                timeToComplete: Int($0.timeToComplete),
                isSelected: $0.isSelected
            )
        } ?? []
        currentTechniques.sort(by: { $0.orderIndex < $1.orderIndex })

        // Load and sort exercises
        currentExercises = (sessionEntity.selectedExercises?.allObjects as? [ExerciseEntity])?.map {
            Exercise(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        } ?? []
        currentExercises.sort(by: { $0.orderIndex < $1.orderIndex })

        // Load other items (katas, blocks, strikes, kicks) similarly
        // ... (This part remains the same as before)

        // Shuffle techniques and exercises if needed
        if session.randomizeTechniques {
            currentTechniques.shuffle()
            currentExercises.shuffle()
            currentKatas.shuffle()
        }

        if !currentTechniques.isEmpty || !currentExercises.isEmpty || !currentKatas.isEmpty {
            currentStep = 0
            announceCurrentItem()
            handleStepWithoutCountdown() // Handle the first item correctly
        } else {
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
                return fetchedSession
            }
        } catch {
            print("Error fetching session: \(error)")
        }
        
        return nil
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
        if currentStep < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count - 1 {
            currentStep += 1
            handleStepWithoutCountdown() // Handle the next step based on type
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

    // New function to handle steps without starting countdown if necessary
    private func handleStepWithoutCountdown() {
        // If the current step is an exercise, pause and wait for user input
        if currentStep >= currentTechniques.count && currentStep < currentTechniques.count + currentExercises.count {
            isExercisePause = true
            announceCurrentItem()
        } else {
            // If not an exercise, continue as usual with countdown
            startCountdown(for: currentItem, countdown: itemCountdown)
        }
    }
}
