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
    private let watchManager = WatchManager.shared

    @State var currentTechniques: [Technique] = []
    @State var currentPracticeType: PracticeType
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

    
    @State private var blockRepetitionCount = 0
    @State private var isWaitingForBlockInput = false
    let totalBlockRepetitions = 10 // Adjust if needed
    
    @State private var viewReady: Bool = false
    @State private var showOptions: Bool = true
    @State private var showSheet: Bool = true
    @State private var selectedOption: String = ""
    
    // Views
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var dataManager: DataManager


    var speechSynthesizer = AVSpeechSynthesizer()
    var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if selectedOption == "Exercise" {
                exerciseContent
            } else if selectedOption == "Quiz" {
                QuizView(session: session)
            } else if selectedOption == "Quiz and Exercise" {
                QuizAndExerciseView(session: session)
            } else {
                Text("Loading...").hidden()
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                viewReady = true
                showSheet = true
                setupTrainingSession()
            }
        }
        .sheet(isPresented: Binding(
            get: { viewReady && showSheet },
            set: { showSheet = $0 }
        )) {
            VStack(spacing: 20) {
                Text("Choose an Option")
                    .font(.largeTitle)
                    .padding()

                Button("Exercise") {
                    selectedOption = "Exercise"
                    showSheet = false
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Quiz") {
                    selectedOption = "Quiz"
                    showSheet = false
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Quiz and Exercise") {
                    selectedOption = "Quiz and Exercise"
                    showSheet = false
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Cancel") {
                    showSheet = false
                    navigateBackToList()
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .edgesIgnoringSafeArea(.all)
        }



    }
    
    private var exerciseContent: some View {
        VStack {
            if sessionComplete {
                VStack(spacing: 20) {
                    Text("Congratulations! You have finished your training session.")
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button(action: {
                        saveTrainingSessionToHistory()
                        navigateBackToList()
                    }) {
                        Text("Save results and return to list")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        navigateBackToList()
                    }) {
                        Text("Don't save results and return to list")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .onAppear{
                    WatchManager.shared.notifyWatchTrainingEnded()
                }
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
                
                if !isExercisePause {
                    Button("Next Item") {
                        advanceToNextStep()
                    }
                    .font(.title)
                    .padding()
                }
            } else if isExercisePause {
                Text(currentItem)
                    .font(.largeTitle)
                    .padding()
                
                if isCurrentItemTechnique {
                    Text("Mode: \(getPracticeType)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("Did not get isCurrentItemTechnique")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
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
                
                if isCurrentItemTechnique {
                    Text("Mode: \(getPracticeType)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("Did not get isCurrentItemTechnique")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
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
                
                if isWaitingForBlockInput {
                    Button("Next Move") {
                        let blockIndex = currentStep - totalTechniquesExercisesKatasAndKicks()
                        
                        // Ensure the block index is valid
                        guard blockIndex >= 0 && blockIndex < currentBlocks.count else {
                            logger.log("Invalid block index at step \(currentStep).")
                            return
                        }
                        
                        let currentBlock = currentBlocks[blockIndex]
                        isWaitingForBlockInput = false // Resume flow
                        startBlockFlow(for: currentBlock) // Continue the block flow
                    }
                    .font(.title)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
            }
            
            
        }
        .navigationTitle("Training Session")
        .onAppear {
            setupTrainingSession()
            
            if isInitialGreeting {
                startCountdown(for: "Square Horse Weapon Sheath", countdown: 10)
            } else {
                logger.log("isInitialGreeting is false. Skipping initial countdown.")
                announceCurrentItem()
                handleStepWithoutCountdown()
            }
            
            // Subscribe to notifications for the gesture and button events
            NotificationCenter.default.addObserver(forName: Notification.Name("NextMoveReceived"), object: nil, queue: .main) { _ in
                logger.log("Next move detected via gesture.")
                advanceToNextStep()
            }
            
            NotificationCenter.default.addObserver(forName: Notification.Name("WatchCommandReceived"), object: nil, queue: .main) { notification in
                if let command = notification.object as? String {
                    handleWatchCommand(command)
                }
            }
            
            NotificationCenter.default.addObserver(forName: .nextMoveReceived, object: nil, queue: .main) { _ in
                print("Next step triggered from notification")
                logger.log("Next move detected via gesture or button.")
                advanceToNextStep()
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


    
    private var isCurrentItemTechnique: Bool {
        return session.techniques.contains(where: { $0.name == currentItem })
    }
    
    private func navigateBackToList() {
        // Send notification to apple watch that training session has ended
        //WatchManager.shared.notifyWatchTrainingEnded()
        presentationMode.wrappedValue.dismiss()
    }

    // Move startTrainingSession to be a private function in StartTrainingView
    private func startTrainingSession() {
        logger.log("Starting the training session.")

        currentStep = 0
        sessionComplete = false
        timerActive = false
        completedItems = []

        // Announce the initial setup instruction
        if isInitialGreeting {
            announce("Square Horse Weapon Sheath")
            startCountdown(for: "Square Horse Weapon Sheath", countdown: 10)
            isInitialGreeting = false
        } else {
            handleStepWithoutCountdown() // Begin the first item if not greeting
        }
    }
    
    private func handleWatchCommand(_ command: String) {
        switch command {
        case "start":
            startTrainingSession()
        case "stop":
            endTrainingSession()
        default:
            break
        }
    }
    
    private var getPracticeType: String {
        return currentPracticeType.rawValue
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
//        guard let sessionEntity = fetchTrainingSessionEntity() else {
//            print("Error: Could not load the session data from CoreData.")
//            sessionComplete = true
//            return
//        }
        guard let sessionEntity = dataManager.getSessionDetails(for: session.id) else {
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
                beltLevel: BeltLevel(rawValue: $0.beltLevel ?? "Unknown") ?? .unknown, // ✅ Fixed conversion
                timeToComplete: Int($0.timeToComplete),
                isSelected: $0.isSelected
            )
        } ?? []

        // ✅ Remove the extra `:` at the end
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
            logger.log("Starting training session.")
            //announceCurrentItem()
            handleStepWithoutCountdown() // Handle the first item correctly
            
            // Update the step on the watch
            updateStepOnWatch()
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
    
    func updateStepOnWatch() {
        let currentStepName = currentItem // Assuming `currentItem` contains the name of the current step
        WatchManager.shared.sendStepNameToWatch(currentStepName)
    }


    private func advanceToNextStep() {
        logger.log("Advancing to step \(currentStep). Total steps: \(totalSteps)")

        updateStepOnWatch()
        
        // Log start and end time for the current step
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

            logger.log("Completed item: \(currentItem) of type \(itemType) in \(timeTaken) seconds.")

            // Send progress update to the watch
            watchManager.sendProgressUpdate(message: "Completed \(currentItem) of type \(itemType)")

            // Save details for specific item types
            switch itemType {
            case "Strike":
                saveStrikeSession(for: currentStep, timestamp: endTime)
            case "Block":
                saveBlockSession(for: currentStep, timestamp: endTime)
            default:
                break
            }
        }

        // Check if the session is complete
        if isTrainingSessionComplete() {
            completeTrainingSession()
            return
        }

        // Proceed to the next step
        currentStep += 1
        strikeRepetitionCount = 0 // Reset strike repetition count
        handleStepWithoutCountdown()
    }

    // MARK: - Helper Methods

    /// Check if the training session is complete
    public func isTrainingSessionComplete() -> Bool {
        return currentStep >= totalSteps - 1
    }

    /// Handle training session completion
    private func completeTrainingSession() {
        sessionComplete = true
        saveTrainingSessionToHistory()
        announce("Congratulations! You have finished your training session.")

        // Send a final progress update to the watch
        watchManager.sendProgressUpdate(message: "Training session completed")
        logger.log("Training session completed.")
        
        // Send a "session finished" message to the watch
        watchManager.sendMessageToWatch(["status": "finished"])
    }

    /// Save strike session details
    private func saveStrikeSession(for step: Int, timestamp: Date) {
        guard step - totalTechniquesExercisesKatasKicksAndBlocks() >= 0 else { return }
        let currentStrike = currentStrikes[step - totalTechniquesExercisesKatasKicksAndBlocks()]
        saveStrikeSession(strike: currentStrike, side: currentSide, timestamp: timestamp)
    }

    /// Save block session details
    private func saveBlockSession(for step: Int, timestamp: Date) {
        guard step - totalTechniquesExercisesKatasAndKicks() >= 0 else { return }
        let currentBlock = currentBlocks[step - totalTechniquesExercisesKatasAndKicks()]
        logger.log("Saving block session for: \(currentBlock.name)")
        saveBlockSession(block: currentBlock, timestamp: timestamp)
        blockRepetitionCount = 0 // Reset block repetition count
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
        logger.log("start announcing: \(text)")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
        logger.log("stop announcing: \(text)")
    }

    private func announceCurrentItem() {
        logger.log("start announcing current item")
        announce(currentItem)
        updateStepOnWatch()
        logger.log("stop announcing current item")
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
            logger.log("Paused for technique")
            announceCurrentItem()
        }
    }

    private func handleExerciseStep() {
        startTime = Date()
        if useTimerForExercises {
            startCountdown(for: currentItem, countdown: timeForExercises)
        } else {
            isExercisePause = true
            logger.log("Paused for exercise")
            announceCurrentItem()
        }
    }

    private func handleKataStep() {
        startTime = Date()
        if useTimerForKatas {
            startCountdown(for: currentItem, countdown: timeForKatas)
        } else {
            isExercisePause = true
            logger.log("Paused for kata")
            announceCurrentItem()
        }
    }

    private func handleKickStep() {
        startTime = Date()
        if useTimerForKicks {
            startCountdown(for: currentItem, countdown: timeForKicks)
        } else {
            isExercisePause = true
            logger.log("Paused for kick")
            announceCurrentItem()
        }
    }

    private func handleBlockStep() {
        let blockIndex = currentStep - totalTechniquesExercisesKatasAndKicks()

        // Ensure the block index is valid
        guard blockIndex < currentBlocks.count else {
            logger.log("Invalid block index: \(blockIndex). Blocks count: \(currentBlocks.count)")
            advanceToNextStep() // Safely advance if out of bounds
            return
        }

        let currentBlock = currentBlocks[blockIndex]
        logger.log("Starting block: \(currentBlock.name)")

        startTime = Date()

        announce("Get into your stance, prepare for \(currentBlock.name)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.startBlockFlow(for: currentBlock)
        }
    }
    
    private func startBlockFlow(for block: Block) {
        // Stop if repetitions are complete
        guard blockRepetitionCount < totalBlockRepetitions else {
            logger.log("Completed \(totalBlockRepetitions) repetitions for \(block.name). Advancing to next block.")
            blockRepetitionCount = 0 // Reset for the next block
            advanceToNextStep()
            return
        }

        // Announce "Move" and log it
        announce("Move")
        logger.log("Move announced for block: \(block.name). Repetition \(blockRepetitionCount + 1)")

        // Increment the repetition count
        blockRepetitionCount += 1

        // Schedule the next repetition with a button press, waiting for user input
        isWaitingForBlockInput = true
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
    
    private func saveBlockSession(block: Block, timestamp: Date) {
        let context = PersistenceController.shared.container.viewContext
        let blockEntity = BlockEntity(context: context)

        blockEntity.name = block.name
        blockEntity.timestamp = timestamp
        blockEntity.repetitions = Int16(blockRepetitionCount)

        do {
            try context.save()
            logger.log("Block session saved: \(block.name)")
        } catch {
            logger.log("Failed to save block session: \(error.localizedDescription)")
        }
    }


}
