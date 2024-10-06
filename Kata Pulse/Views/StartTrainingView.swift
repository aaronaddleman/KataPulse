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
    @State var isExercisePause = false

    // Toggles for each category to switch between pause and timer
    @State var useTimerForTechniques = true
    @State var useTimerForExercises = false
    @State var useTimerForKatas = true
    @State var useTimerForBlocks = true
    @State var useTimerForStrikes = true
    @State var useTimerForKicks = true
    
    @State var timeForKatas: Int = 30
    @State var timeForExercises: Int = 10
    @State var timeForBlocks: Int = 15
    @State var timeForStrikes: Int = 15
    @State var timeForKicks: Int = 20
    @State var timeForTechniques: Int = 10
    
    // Info for saving training history
    @State private var startTime: Date? = nil
    @State private var endTime: Date? = nil
    @State private var completedItems: [TrainingSessionHistoryItem] = []


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
            return timeForTechniques
        } else if currentStep - currentTechniques.count < currentExercises.count {
            return timeForExercises
        } else if currentStep - currentTechniques.count - currentExercises.count < currentKatas.count {
            return timeForKatas
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count <
            currentKicks.count {
            return timeForKicks
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count < currentBlocks.count {
            return timeForBlocks
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count - currentBlocks.count < currentStrikes.count {
            return timeForStrikes
        } else {
            return 10 // Default value if something goes wrong
        }
    }

    private func setupTrainingSession() {
        guard let sessionEntity = fetchTrainingSessionEntity() else {
            print("Error: Could not load the session data from CoreData.")
            sessionComplete = true
            return
        }

        // Load the useTimerFor* properties from the Core Data entity
        useTimerForTechniques = sessionEntity.useTimerForTechniques
        useTimerForExercises = sessionEntity.useTimerForExercises
        useTimerForKatas = sessionEntity.useTimerForKatas
        useTimerForBlocks = sessionEntity.useTimerForBlocks
        useTimerForStrikes = sessionEntity.useTimerForStrikes
        useTimerForKicks = sessionEntity.useTimerForKicks
        
        // Load the timer values from the Core Data entity
        timeForTechniques = Int(sessionEntity.timeForTechniques)
        print("Loaded timeForTechniques: \(timeForTechniques)")
        timeForKatas = Int(sessionEntity.timeForKatas)
        timeForExercises = Int(sessionEntity.timeForExercises)
        timeForBlocks = Int(sessionEntity.timeForBlocks)
        timeForStrikes = Int(sessionEntity.timeForStrikes)
        timeForKicks = Int(sessionEntity.timeForKicks)

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

        // Load and sort katas
        currentKatas = (sessionEntity.selectedKatas?.allObjects as? [KataEntity])?.map {
            Kata(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                kataNumber: Int($0.kataNumber),
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        } ?? []
        currentKatas.sort(by: { $0.orderIndex < $1.orderIndex })

        // Load and sort strikes
        currentStrikes = (sessionEntity.selectedStrikes?.allObjects as? [StrikeEntity])?.map {
            Strike(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        } ?? []
        currentStrikes.sort(by: { $0.orderIndex < $1.orderIndex })

        // Load and sort blocks
        currentBlocks = (sessionEntity.selectedBlocks?.allObjects as? [BlockEntity])?.map {
            Block(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        } ?? []
        currentBlocks.sort(by: { $0.orderIndex < $1.orderIndex })

        // Load and sort kicks
        currentKicks = (sessionEntity.selectedKicks?.allObjects as? [KickEntity])?.map {
            Kick(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        } ?? []

        currentKicks.sort(by: { $0.orderIndex < $1.orderIndex })
        
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
        // Before advancing to the next step, store the completed item
        if let startTime = startTime {
            endTime = Date()
            let timeTaken = endTime?.timeIntervalSince(startTime) ?? 0

            // Create a TrainingSessionHistoryItem for the current item
            let completedItem = TrainingSessionHistoryItem(
                id: UUID(),
                exerciseName: currentItem, // You can replace this with `currentItem`'s id if needed
                timeTaken: timeTaken,
                type: getItemType(for: currentStep) // A function to determine if it's a technique, kata, etc.
            )
            
            completedItems.append(completedItem)
        }
        
        // Existing logic to advance to the next step
        if currentStep < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count + currentKicks.count - 1 {
            currentStep += 1
            handleStepWithoutCountdown() // Handle the next step based on type
        } else {
            sessionComplete = true
            saveTrainingSessionToHistory()
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

    private func handleStepWithoutCountdown() {
        // Check the toggle for each category to either use a pause or a timer
        if currentStep < currentTechniques.count {
            if useTimerForTechniques {
                print("Current timer set to timeForTechniques: \(timeForTechniques)")
                startCountdown(for: currentItem, countdown: timeForTechniques)
            } else {
                isExercisePause = true
                announceCurrentItem()
            }
        } else if currentStep - currentTechniques.count < currentExercises.count {
            if useTimerForExercises {
                startCountdown(for: currentItem, countdown: timeForExercises)
            } else {
                isExercisePause = true
                announceCurrentItem()
            }
        } else if currentStep - currentTechniques.count - currentExercises.count < currentKatas.count {
            if useTimerForKatas {
                startCountdown(for: currentItem, countdown: timeForKatas)
            } else {
                isExercisePause = true
                announceCurrentItem()
            }
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count < currentKicks.count {
            if useTimerForKicks {
                startCountdown(for: currentItem, countdown: timeForKicks)
            } else {
                isExercisePause = true
                announceCurrentItem()
            }
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count < currentBlocks.count {
            if useTimerForBlocks {
                startCountdown(for: currentItem, countdown: timeForBlocks)
            } else {
                isExercisePause = true
                announceCurrentItem()
            }
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count - currentBlocks.count < currentStrikes.count {
            if useTimerForStrikes {
                startCountdown(for: currentItem, countdown: timeForStrikes)
            } else {
                isExercisePause = true
                announceCurrentItem()
            }
        }
    }
    
    private func startExercise() {
        startTime = Date() // Track the start time of the exercise
    }
    
    private func endExercise() {
        if let startTime = startTime {
            endTime = Date()
            let timeTaken = endTime?.timeIntervalSince(startTime) ?? 0
            // Store the timeTaken for this exercise
            print("Time taken: \(timeTaken) seconds")
        }
    }
    
    private func saveTrainingSessionToHistory() {
        let context = PersistenceController.shared.container.viewContext
        let historyEntity = TrainingSessionHistoryEntity(context: context)
        historyEntity.id = UUID()
        historyEntity.sessionName = session.name
        historyEntity.timestamp = Date()

        // Logging the completed items
        print("Saving history for session: \(session.name)")
        print("Number of completed items: \(completedItems.count)")

        // Convert completedItems to Core Data entities
        let historyItems = completedItems.map { item -> TrainingSessionHistoryItemsEntity in
            let itemEntity = TrainingSessionHistoryItemsEntity(context: context)
            itemEntity.id = item.id
            itemEntity.exerciseName = item.exerciseName
            itemEntity.timeTaken = item.timeTaken
            itemEntity.type = item.type
            itemEntity.history = historyEntity // Set reverse relationship
            print("Saving item: \(item.exerciseName) with time taken: \(item.timeTaken)")
            return itemEntity
        }

        historyEntity.items = NSSet(array: historyItems) // Set the relationship

        do {
            try context.save()
            print("Training session history saved.")
        } catch {
            print("Failed to save training session history: \(error)")
        }
    }

    private func getItemType(for step: Int) -> String {
        if step < currentTechniques.count {
            return "Technique"
        } else if step < currentTechniques.count + currentExercises.count {
            return "Exercise"
        } else if step < currentTechniques.count + currentExercises.count + currentKatas.count {
            return "Kata"
        } else if step < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count {
            return "Block"
        } else if step < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count {
            return "Strike"
        } else if step < currentTechniques.count + currentExercises.count + currentKatas.count + currentBlocks.count + currentStrikes.count + currentKicks.count {
            return "Kick"
        } else {
            return "Unknown"
        }
    }


}
