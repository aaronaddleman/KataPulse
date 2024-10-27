//
//  StartTrainingView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import AVFoundation
import CoreData
import os.log

struct StartTrainingView: View {
    let session: TrainingSession
    private let logger = Logger(subsystem: "com.example.KataPulse", category: "StartTrainingView")

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
    @State var timeForBlocks: Int = 5
    @State var timeForStrikes: Int = 15
    @State var timeForKicks: Int = 20
    @State var timeForTechniques: Int = 10
    
    // Info for saving training history
    @State private var startTime: Date? = nil
    @State private var endTime: Date? = nil
    @State private var completedItems: [TrainingSessionHistoryItem] = []
    
    // Strikes
    @State private var currentSide = "Right"
    @State private var strikeRepetitionCount = 0
    @State private var isAlternatingPunch = false
    @State private var totalRepetitions = 6 // Default repetitions for most strikes

    @State private var isWaitingForUser = false // New state to pause between moves

    @State private var hasAnnouncedSetup = false // Tracks if setup instructions are announced
    @State private var isPerformingStrikeFlow = false // Tracks if repetitions are in progress
    @State private var hasAnnouncedFirstStrike = false // Track if the first strike has been announced
    @State private var isPerformingRepetitions = false



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
                Text(currentItem)
                    .font(.largeTitle)
                    .padding()

                Button("Next Exercise") {
                    isExercisePause = false
                    advanceToNextStep()
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

                // Show Next Move button only during strike flow
                if isWaitingForUser {
                    Button("Next Move") {
                        isWaitingForUser = false // Resume the flow

                        let index = currentStep - totalTechniquesExercisesKatasKicksAndBlocks()
                        guard index >= 0 && index < currentStrikes.count else {
                            logger.log("Invalid strike index at step \(currentStep).")
                            return
                        }

                        let currentStrike = currentStrikes[index]
                        logger.log("Continuing strike: \(currentStrike.name) on side: \(currentSide).")
                        
                        // Resume the strike flow with the next repetition
                        startStrikeFlow(for: currentStrike)
                    }
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }

            if !isExercisePause {
                Button("Next Item") {
                    advanceToNextStep()
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
                handleStepWithoutCountdown()
            }
        }
        .onDisappear {
            endTrainingSession()
        }
        .onReceive(timerPublisher) { _ in
            if timerActive && countdown > 0 {
                countdown -= 1
            } else if countdown == 0 && timerActive {
                timerActive = false

                if isInitialGreeting {
                    isInitialGreeting = false
                    handleStepWithoutCountdown()
                } else {
                    advanceToNextStep()
                }
            }
        }
    }

    // The current item (technique, exercise, kata, block, strike) based on the current step
    private var currentItem: String {
        let offset = currentStep

        let item: String
        if offset < currentTechniques.count {
            item = currentTechniques[offset].name
        } else if offset < totalTechniquesAndExercises() {
            item = currentExercises[offset - currentTechniques.count].name
        } else if offset < totalTechniquesExercisesAndKatas() {
            item = currentKatas[offset - totalTechniquesAndExercises()].name
        } else if offset < totalTechniquesExercisesKatasAndKicks() {
            item = currentKicks[offset - totalTechniquesExercisesAndKatas()].name
        } else if offset < totalTechniquesExercisesKatasKicksAndBlocks() {
            item = currentBlocks[offset - totalTechniquesExercisesKatasAndKicks()].name
        } else if offset < totalTechniquesExercisesKatasKicksBlocksAndStrikes() {
            item = currentStrikes[offset - totalTechniquesExercisesKatasKicksAndBlocks()].name
        } else {
            item = "No more items"
        }

        logger.log("Displaying item: \(item) at step \(currentStep)")
        return item
    }

    // Duration for the current item's countdown timer
    private var itemCountdown: Int {
        let offset = currentStep // Track the current step

        // Use helper functions to calculate offsets cleanly
        if offset < currentTechniques.count {
            return timeForTechniques
        } else if offset < totalTechniquesAndExercises() {
            return timeForExercises
        } else if offset < totalTechniquesExercisesAndKatas() {
            return timeForKatas
        } else if offset < totalTechniquesExercisesKatasAndKicks() {
            return timeForKicks
        } else if offset < totalTechniquesExercisesKatasKicksAndBlocks() {
            return timeForBlocks
        } else if offset < totalTechniquesExercisesKatasKicksBlocksAndStrikes() {
            return timeForStrikes
        } else {
            return 10 // Default value if something goes wrong
        }
    }

    // MARK: - Helper Functions for Offsets

    private func totalTechniquesAndExercises() -> Int {
        return currentTechniques.count + currentExercises.count
    }

    private func totalTechniquesExercisesAndKatas() -> Int {
        return totalTechniquesAndExercises() + currentKatas.count
    }

    private func totalTechniquesExercisesKatasAndKicks() -> Int {
        return totalTechniquesExercisesAndKatas() + currentKicks.count
    }

    private func totalTechniquesExercisesKatasKicksAndBlocks() -> Int {
        return totalTechniquesExercisesKatasAndKicks() + currentBlocks.count
    }

    private func totalTechniquesExercisesKatasKicksBlocksAndStrikes() -> Int {
        return totalTechniquesExercisesKatasKicksAndBlocks() + currentStrikes.count
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
        currentStrikes = (sessionEntity.selectedStrikes?.allObjects as? [StrikeEntity])?.map { strikeEntity in
            Strike(
                id: strikeEntity.id ?? UUID(),
                name: strikeEntity.name ?? "Unnamed",
                orderIndex: Int(strikeEntity.orderIndex),
                isSelected: strikeEntity.isSelected,
                type: strikeEntity.type ?? "Unknown",
                preferredStance: strikeEntity.preferredStance ?? "None",
                repetitions: Int(strikeEntity.repetitions),
                timePerMove: Int(strikeEntity.timePerMove),
                requiresBothSides: strikeEntity.requiresBothSides,
                leftCompleted: strikeEntity.leftCompleted,
                rightCompleted: strikeEntity.rightCompleted
            )
        } ?? []
        currentStrikes.sort(by: { $0.orderIndex < $1.orderIndex })
        logger.log("Loaded \(currentStrikes.count) strikes.")

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
        logger.log("Loaded kicks: \(currentKicks.map { $0.name })")

        
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
        logger.log("Advancing to step \(currentStep). Total steps: \(totalSteps)")

        if let startTime = startTime {
            let endTime = Date()
            let timeTaken = endTime.timeIntervalSince(startTime)

            let itemType = getItemType(for: currentStep)
            let completedItem = TrainingSessionHistoryItem(
                id: UUID(),
                exerciseName: currentItem,
                timeTaken: timeTaken,
                type: itemType
            )
            completedItems.append(completedItem)

            // Save the strike session if it's a strike
            if itemType == "Strike" {
                let currentStrike = currentStrikes[currentStep - totalTechniquesExercisesKatasKicksAndBlocks()]
                saveStrikeSession(strike: currentStrike, side: currentSide, timestamp: endTime)
            }
        }

        // Move to the next step or complete the session
        if currentStep < totalSteps - 1 {
            currentStep += 1
            strikeRepetitionCount = 0 // Reset the repetition count
            handleStepWithoutCountdown()
        } else {
            sessionComplete = true
            saveTrainingSessionToHistory()
            announce("Congratulations! You have finished your training session.")
        }
    }

    // Computed property to get the total number of steps in the training session
    private var totalSteps: Int {
        return currentTechniques.count +
               currentExercises.count +
               currentKatas.count +
               currentBlocks.count +
               currentStrikes.count +
               currentKicks.count
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
            handleTechniqueStep()
        } else if currentStep - currentTechniques.count < currentExercises.count {
            handleExerciseStep()
        } else if currentStep - currentTechniques.count - currentExercises.count < currentKatas.count {
            handleKataStep()
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count < currentKicks.count {
            handleKickStep()
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count < currentBlocks.count {
            handleBlockStep()
        } else if currentStep - currentTechniques.count - currentExercises.count - currentKatas.count - currentKicks.count - currentBlocks.count < currentStrikes.count {
            handleStrikeStep()
        }
    }

    // MARK: - Category Handlers

    private func handleTechniqueStep() {
        startTime = Date() // Track the start time
        if useTimerForTechniques {
            startCountdown(for: currentItem, countdown: timeForTechniques)
        } else {
            isExercisePause = true
            announceCurrentItem()
        }
    }

    private func handleExerciseStep() {
        startTime = Date()
        if useTimerForExercises {
            startCountdown(for: currentItem, countdown: timeForExercises)
        } else {
            isExercisePause = true
            announceCurrentItem()
        }
    }

    private func handleKataStep() {
        startTime = Date()
        if useTimerForKatas {
            startCountdown(for: currentItem, countdown: timeForKatas)
        } else {
            isExercisePause = true
            announceCurrentItem()
        }
    }

    private func handleKickStep() {
        startTime = Date()
        if useTimerForKicks {
            startCountdown(for: currentItem, countdown: timeForKicks)
        } else {
            isExercisePause = true
            announceCurrentItem()
        }
    }

    private func handleBlockStep() {
        startTime = Date()
        if useTimerForBlocks {
            startCountdown(for: currentItem, countdown: timeForBlocks)
        } else {
            isExercisePause = true
            announceCurrentItem()
        }
    }

    private func handleStrikeStep() {
        let strikeIndex = currentStep - totalTechniquesExercisesKatasKicksAndBlocks()

        // Check if the strike index is valid
        guard strikeIndex < currentStrikes.count else {
            logger.log("Invalid strike index: \(strikeIndex). Strikes count: \(currentStrikes.count)")
            advanceToNextStep()
            return
        }

        let currentStrike = currentStrikes[strikeIndex]
        logger.log("Starting strike: \(currentStrike.name) on \(currentSide) side.")

        startTime = Date()

        // Check if the strike is a punch and handle the announcement logic
        if currentStrike.name == "Punch" && !hasAnnouncedFirstStrike {
            announce("Starting with the \(currentSide) fist out")
            hasAnnouncedFirstStrike = true // Prevent further announcements for punches
        } else if currentStrike.name != "Punch" {
            announce(currentStrike.name) // Announce other strikes
        }

        // Begin the strike flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.startStrikeFlow(for: currentStrike)
        }
    }

    

    // MARK: - Helpers for Strike Logic

    private func startAlternatingPunches(for strike: Strike) {
        guard strikeRepetitionCount < 5 else {
            advanceToNextStep()
            return
        }

        // Announce the punch and alternate sides
        announce("Move")
        strikeRepetitionCount += 1
        currentSide = (currentSide == "Right") ? "Left" : "Right" // Switch sides

        // Set the timer for the next punch
        Timer.scheduledTimer(withTimeInterval: TimeInterval(timeForStrikes), repeats: false) { _ in
            self.startAlternatingPunches(for: strike)
        }
    }

    private func startStrikeFlow(for strike: Strike) {
        // Stop if repetitions are complete
        guard strikeRepetitionCount < 10 else {
            logger.log("Completed 10 repetitions for \(strike.name). Advancing to next strike.")
            advanceToNextStep()
            return
        }

        // Announce "Move" and log it
        announce("Move")
        logger.log("Move announced for strike: \(strike.name) on side: \(currentSide). Repetition \(strikeRepetitionCount + 1)")

        // Increment the repetition count
        strikeRepetitionCount += 1

        // Set the state to wait for the user to hit "Next Move"
        isWaitingForUser = true
    }


    
    // Method to continue the strike flow after the "Next Move" button is pressed
    private func continueStrikeFlow() {
        // Resume the strike flow
        startStrikeFlow(for: currentStrikes[currentStep - totalTechniquesExercisesKatasKicksAndBlocks()])
    }

    private func switchSidesIfNeeded(for strike: Strike) {
        let timestamp = Date() // Track when the side was completed

        // Save progress for the current side
        saveStrikeSession(strike: strike, side: currentSide, timestamp: timestamp)

        if currentSide == "Right" {
            // Switch to the left side
            currentSide = "Left"
            strikeRepetitionCount = 0
            announce("Switch sides, Left leg back, guards up")
            startStrikeFlow(for: strike)
        } else {
            // Both sides completed, move to the next step
            advanceToNextStep()
        }
    }

    // MARK: - Utility Functions

    private func totalTechniquesAndExercisesAndKatas() -> Int {
        return currentTechniques.count + currentExercises.count + currentKatas.count
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
        print("Saving history for session: \(session.name)")
        print("Number of completed items: \(completedItems.count)")

        guard !completedItems.isEmpty else {
            print("No completed items to save.")
            return
        }

        let context = PersistenceController.shared.container.viewContext
        let historyEntity = TrainingSessionHistoryEntity(context: context)
        historyEntity.id = UUID()
        historyEntity.sessionName = session.name
        historyEntity.timestamp = Date()
        
        for item in completedItems {
            let itemEntity = item.toEntity(context: context)
            itemEntity.history = historyEntity // Setting the relationship
            historyEntity.addToItems(itemEntity) // Adding the items to the history
        }

        do {
            try context.save()
            print("Training session history saved.")
        } catch {
            print("Failed to save training session history: \(error.localizedDescription)")
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

    private func saveStrikeSession(strike: Strike, side: String, timestamp: Date) {
        let context = PersistenceController.shared.container.viewContext
        let strikeEntity = StrikeEntity(context: context)

        strikeEntity.name = strike.name
        strikeEntity.type = strike.type
        strikeEntity.preferredStance = strike.preferredStance
        strikeEntity.repetitions = Int16(strikeRepetitionCount)
        strikeEntity.timePerMove = Int16(timeForStrikes)
        strikeEntity.timestamp = timestamp
        strikeEntity.leftCompleted = (side == "Left")
        strikeEntity.rightCompleted = (side == "Right")

        do {
            try context.save()
            print("Strike session saved.")
        } catch {
            print("Failed to save strike session: \(error.localizedDescription)")
        }
    }

}
