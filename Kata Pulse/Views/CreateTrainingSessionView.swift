//
//  CreateTrainingSessionView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import CoreData

struct CreateTrainingSessionView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: DataManager

    var editingSession: TrainingSessionEntity?

    @State private var sessionName: String = ""
    @State private var selectedTechniques: [Technique] = []
    @State private var selectedExercises: [Exercise] = []
    @State private var selectedKatas: [Kata] = []
    @State private var selectedBlocks: [Block] = []
    @State private var selectedStrikes: [Strike] = []
    @State private var selectedKicks: [Kick] = []
    @State private var randomizeTechniques: Bool = false
    @State private var isFeetTogetherEnabled: Bool = false
    @State private var timeBetweenTechniques: Int = 5

    // Toggles for pausing vs. timer per category
    @State private var useTimerForTechniques: Bool = true
    @State private var useTimerForExercises: Bool = false
    @State private var useTimerForKatas: Bool = true
    @State private var useTimerForBlocks: Bool = true
    @State private var useTimerForStrikes: Bool = true
    @State private var useTimerForKicks: Bool = true
    
    // Timmer values
    @State private var timeForKatas: Int = 30
    @State private var timeForExercises: Int = 10
    @State private var timeForBlocks: Int = 5
    @State private var timeForStrikes: Int = 15
    @State private var timeForKicks: Int = 20
    @State private var timeForTechniques: Int = 10
    
    // Practice Types
    @State private var selectedPracticeType: PracticeType = .soundOff
    
    var body: some View {
        Form {
            Section(header: Text("Session Info")) {
                TextField("Session Name", text: $sessionName)

                Toggle(isOn: $randomizeTechniques) {
                    Text("Randomize Techniques")
                }

                Toggle(isOn: $isFeetTogetherEnabled) {
                    Text("Feet Together Mode")
                }

                // Timer/Pause Toggles for Techniques
                Toggle(isOn: $useTimerForTechniques) {
                    Text(useTimerForTechniques ? "Use Timer for Techniques" : "Pause for Techniques")
                }
                
                Section(header: Text("Practice Type for Techniques")) {
                                Picker("Practice Type", selection: $selectedPracticeType) {
                                    ForEach(PracticeType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle()) // Use .MenuPickerStyle() for dropdown
                            }

                // Timer/Pause Toggles for Exercises
                Toggle(isOn: $useTimerForExercises) {
                    Text(useTimerForExercises ? "Use Timer for Exercises" : "Pause for Exercises")
                }

                // Timer/Pause Toggles for Katas
                Toggle(isOn: $useTimerForKatas) {
                    Text(useTimerForKatas ? "Use Timer for Katas" : "Pause for Katas")
                }

                // Timer/Pause Toggles for Blocks
                Toggle(isOn: $useTimerForBlocks) {
                    Text(useTimerForBlocks ? "Use Timer for Blocks" : "Pause for Blocks")
                }

                // Timer/Pause Toggles for Strikes
                Toggle(isOn: $useTimerForStrikes) {
                    Text(useTimerForStrikes ? "Use Timer for Strikes" : "Pause for Strikes")
                }

                // Timer/Pause Toggles for Kicks
                Toggle(isOn: $useTimerForKicks) {
                    Text(useTimerForKicks ? "Use Timer for Kicks" : "Pause for Kicks")
                }

                Section(header: Text("Set Timer Durations")) {
                    Stepper("Time for Techniques: \(timeForTechniques) seconds", value: $timeForTechniques, in: 1...30)
                    Stepper("Time for Katas: \(timeForKatas) seconds", value: $timeForKatas, in: 1...60)
                    Stepper("Time for Exercises: \(timeForExercises) seconds", value: $timeForExercises, in: 1...60)
                    Stepper("Time for Blocks: \(timeForBlocks) seconds", value: $timeForBlocks, in: 1...60)
                    Stepper("Time for Strikes: \(timeForStrikes) seconds", value: $timeForStrikes, in: 1...60)
                    Stepper("Time for Kicks: \(timeForKicks) seconds", value: $timeForKicks, in: 1...60)
                }

            }

            // CreateTrainingSessionView
            Section(header: Text("Techniques")) {
                List {
                    ForEach(Array(selectedTechniques.enumerated()), id: \.element.id) { index, technique in
                        HStack {
                            Text(technique.name)
                            Spacer()
                            if technique.isSelected {
                                Image(systemName: "checkmark")
                            }
                            Image(systemName: "line.horizontal.3")
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(technique.backgroundColor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleTechniqueSelection(at: index) // Update by index
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedTechniques.move(fromOffsets: indices, toOffset: newOffset)
                        updateOrderIndexes() // Update the orderIndex values
                        saveSessionOrder() // Save the order to Core Data
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            // Kicks Section
            Section(header: Text("Kicks")) {
                List {
                    ForEach(Array(selectedKicks.enumerated()), id: \.element.id) { index, kick in
                        HStack {
                            Text(kick.name)
                            Spacer()
                            if kick.isSelected {
                                Image(systemName: "checkmark")
                            }
                            Image(systemName: "line.horizontal.3")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleKickSelection(at: index) // Update by index
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedKicks.move(fromOffsets: indices, toOffset: newOffset)
                        updateKickOrderIndexes() // Update the orderIndex values
                        saveSessionOrder() // Save the order to Core Data
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }
            
            // Exercises Section
            Section(header: Text("Exercises")) {
                List {
                    ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            if exercise.isSelected {
                                Image(systemName: "checkmark")
                            }
                            Image(systemName: "line.horizontal.3")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleExerciseSelection(at: index) // Update by index
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedExercises.move(fromOffsets: indices, toOffset: newOffset)
                        updateExerciseOrderIndexes() // Update the orderIndex values
                        saveSessionOrder() // Save the order to Core Data
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            Section(header: Text("Katas")) {
                List {
                    ForEach(Array(selectedKatas.enumerated()), id: \.element.id) { index, kata in
                        HStack {
                            Text(kata.name)
                            Spacer()
                            if kata.isSelected {
                                Image(systemName: "checkmark")
                            }
                            Image(systemName: "line.horizontal.3")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleKataSelection(at: index)
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedKatas.move(fromOffsets: indices, toOffset: newOffset)
                        updateKataOrderIndexes() // Update order index values
                        saveSessionOrder() // Save the new order to Core Data
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            // Blocks Section
            Section(header: Text("Blocks")) {
                List {
                    ForEach(Array(selectedBlocks.enumerated()), id: \.element.id) { index, block in
                        HStack {
                            Text(block.name)
                            Spacer()
                            if block.isSelected {
                                Image(systemName: "checkmark")
                            }
                            Image(systemName: "line.horizontal.3")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleBlockSelection(at: index) // Update by index
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedBlocks.move(fromOffsets: indices, toOffset: newOffset)
                        updateBlockOrderIndexes() // Update the orderIndex values
                        saveSessionOrder() // Save the order to Core Data
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            // Strikes Section
            Section(header: Text("Strikes")) {
                List {
                    ForEach(Array(selectedStrikes.enumerated()), id: \.element.id) { index, strike in
                        HStack {
                            Text(strike.name)
                            Spacer()
                            if strike.isSelected {
                                Image(systemName: "checkmark")
                            }
                            Image(systemName: "line.horizontal.3")
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleStrikeSelection(at: index) // Update by index
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedStrikes.move(fromOffsets: indices, toOffset: newOffset)
                        updateStrikeOrderIndexes() // Update the orderIndex values
                        saveSessionOrder() // Save the order to Core Data
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            Button(action: saveSession) {
                Text(editingSession == nil ? "Create Session" : "Save Changes")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
            }
        }
        .navigationTitle(editingSession == nil ? "Create Training Session" : "Edit Training Session")
        .onAppear {
            print("Editing session: \(editingSession?.name ?? "No session")")
            if let session = editingSession {
                print("Editing session onAppear for session: \(session.name ?? "Unammed session")")
                let sessionData = dataManager.loadSessionData(session)
                sessionName = sessionData.name
                randomizeTechniques = sessionData.randomizeTechniques
                isFeetTogetherEnabled = sessionData.isFeetTogetherEnabled
                selectedPracticeType = sessionData.practiceType
                timeBetweenTechniques = sessionData.timeBetweenTechniques
                useTimerForTechniques = sessionData.useTimerForTechniques
                useTimerForExercises = sessionData.useTimerForExercises
                useTimerForKatas = sessionData.useTimerForKatas
                useTimerForBlocks = sessionData.useTimerForBlocks
                useTimerForStrikes = sessionData.useTimerForStrikes
                useTimerForKicks = sessionData.useTimerForKicks
                timeForTechniques = sessionData.timeForTechniques
                timeForExercises = sessionData.timeForExercises
                timeForKatas = sessionData.timeForKatas
                timeForBlocks = sessionData.timeForBlocks
                timeForStrikes = sessionData.timeForStrikes
                timeForKicks = sessionData.timeForKicks
                selectedTechniques = sessionData.selectedTechniques
                selectedExercises = sessionData.selectedExercises
                selectedBlocks = sessionData.selectedBlocks
                selectedStrikes = sessionData.selectedStrikes
                selectedKatas = sessionData.selectedKatas
                selectedKicks = sessionData.selectedKicks
                
                // Ensure all predefined lists are populated
                selectedTechniques = populateAndSort(
                    predefinedItems: predefinedTechniques,
                    selectedItems: sessionData.selectedTechniques,
                    sortCriteria: {$0.orderIndex < $1.orderIndex }
                )
                selectedExercises = populateAndSort(
                    predefinedItems: predefinedExercises,
                    selectedItems: sessionData.selectedExercises,
                    sortCriteria: {$0.orderIndex < $1.orderIndex }
                )
                selectedBlocks = populateAndSort(
                    predefinedItems: predefinedBlocks,
                    selectedItems: sessionData.selectedBlocks,
                    sortCriteria: {$0.orderIndex < $1.orderIndex }
                )
                selectedStrikes = populateAndSort(
                    predefinedItems: predefinedStrikes,
                    selectedItems: sessionData.selectedStrikes,
                    sortCriteria: {$0.orderIndex < $1.orderIndex }
                )
                selectedKatas = populateAndSort(
                    predefinedItems: predefinedKatas,
                    selectedItems: sessionData.selectedKatas,
                    sortCriteria: {$0.orderIndex < $1.orderIndex }
                )
                selectedKicks = populateAndSort(
                    predefinedItems: predefinedKicks,
                    selectedItems: sessionData.selectedKicks,
                    sortCriteria: { $0.orderIndex < $1.orderIndex }
                )
                
                print("Loadded session data: \(sessionData)")
            } else {
                print("No session provided for editing; preparing a new session.")
                let newSessionData = dataManager.prepareForNewSession()
                // Populate for a new session
                sessionName = newSessionData.name
                randomizeTechniques = newSessionData.randomizeTechniques
                isFeetTogetherEnabled = newSessionData.isFeetTogetherEnabled
                selectedPracticeType = newSessionData.practiceType
                timeBetweenTechniques = newSessionData.timeBetweenTechniques
                useTimerForTechniques = newSessionData.useTimerForTechniques
                useTimerForExercises = newSessionData.useTimerForExercises
                useTimerForKatas = newSessionData.useTimerForKatas
                useTimerForBlocks = newSessionData.useTimerForBlocks
                useTimerForStrikes = newSessionData.useTimerForStrikes
                useTimerForKicks = newSessionData.useTimerForKicks
                timeForTechniques = newSessionData.timeForTechniques
                timeForExercises = newSessionData.timeForExercises
                timeForKatas = newSessionData.timeForKatas
                timeForBlocks = newSessionData.timeForBlocks
                timeForStrikes = newSessionData.timeForStrikes
                timeForKicks = newSessionData.timeForKicks
                selectedTechniques = newSessionData.selectedTechniques
                selectedExercises = newSessionData.selectedExercises
                selectedBlocks = newSessionData.selectedBlocks
                selectedStrikes = newSessionData.selectedStrikes
                selectedKatas = newSessionData.selectedKatas
                selectedKicks = newSessionData.selectedKicks
                print("Prepared new session data: \(newSessionData)")
            }
        }
    }
    
    // Helper function to populate and sort predefined items
    private func populateAndSort<T: Identifiable & Equatable>(
        predefinedItems: [T],
        selectedItems: [T],
        sortCriteria: (T, T) -> Bool
    ) -> [T] {
        var items = selectedItems
        
        for predefinedItem in predefinedItems where !items.contains(where: { $0.id == predefinedItem.id }) {
            var item = predefinedItem
            if var mutableItem = item as? Selectable {
                mutableItem.isSelected = false
                items.append(mutableItem as! T)
            }
        }
        
        items.sort(by: sortCriteria)
        return items
    }


    private func toggleTechniqueSelection(at index: Int) {
        // Toggle the selected state at the index
        selectedTechniques[index].isSelected.toggle()
        print("Toggled technique: \(selectedTechniques[index].name), selected: \(selectedTechniques[index].isSelected)")
    }

    // Helper to toggle selection for exercises
    private func toggleExerciseSelection(at index: Int) {
        selectedExercises[index].isSelected.toggle()
        print("Toggled exercise: \(selectedExercises[index].name), selected: \(selectedExercises[index].isSelected)")
    }

    private func updateExerciseOrderIndexes() {
        for (index, exercise) in selectedExercises.enumerated() {
            selectedExercises[index].orderIndex = index
            print("Updated exercise: \(exercise.name), new orderIndex: \(index)")
        }
    }

    private func updateKickOrderIndexes() {
        for index in 0..<selectedKicks.count {
            selectedKicks[index].orderIndex = index
        }
    }

    private func toggleKataSelection(at index: Int) {
        selectedKatas[index].isSelected.toggle()
        print("Toggled kata: \(selectedKatas[index].name), selected: \(selectedKatas[index].isSelected)")
    }
    
    private func updateKataOrderIndexes() {
        for (index, kata) in selectedKatas.enumerated() {
            selectedKatas[index].orderIndex = index
            print("Updated kata: \(kata.name), new orderIndex: \(index)")
        }
    }

    private func toggleBlockSelection(at index: Int) {
        selectedBlocks[index].isSelected.toggle()
        print("Toggled block: \(selectedBlocks[index].name), selected: \(selectedBlocks[index].isSelected)")
    }
    
    private func updateBlockOrderIndexes() {
        for (index, block) in selectedBlocks.enumerated() {
            selectedBlocks[index].orderIndex = index
            print("Updated block: \(block.name), new orderIndex: \(index)")
        }
    }
    
    // Helper to toggle selection for strikes
    private func toggleStrikeSelection(at index: Int) {
        selectedStrikes[index].isSelected.toggle()
        print("Toggled strike: \(selectedStrikes[index].name), selected: \(selectedStrikes[index].isSelected)")
    }
    
    // Helper to toggle selection for kicks
    private func toggleKickSelection(at index: Int) {
        selectedKicks[index].isSelected.toggle()
        print("Toggled kick: \(selectedKicks[index].name), selected: \(selectedKicks[index].isSelected)")
    }

    // Helper to update orderIndex for strikes
    private func updateStrikeOrderIndexes() {
        for (index, strike) in selectedStrikes.enumerated() {
            selectedStrikes[index].orderIndex = index
            print("Updated strike: \(strike.name), new orderIndex: \(index)")
        }
    }
    
    private func updateOrderIndexes() {
        for index in selectedTechniques.indices {
            selectedTechniques[index].orderIndex = index
            print("Updated technique: \(selectedTechniques[index].name), new orderIndex: \(selectedTechniques[index].orderIndex)")
        }
    }

    private func saveSessionOrder() {
        // Fetch the current session from Core Data
        guard let session = editingSession else { return }
        
        // Clear existing selected techniques, exercises, blocks, and strikes
        session.selectedTechniques = nil
        session.selectedExercises = nil
        session.selectedBlocks = nil
        session.selectedStrikes = nil
        session.selectedKicks = nil
        
        // Save the updated techniques order to the session
        for (index, technique) in selectedTechniques.enumerated() {
            let techniqueEntity = TechniqueEntity(context: context)
            techniqueEntity.id = technique.id
            techniqueEntity.name = technique.name
            techniqueEntity.beltLevel = technique.beltLevel
            techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
            techniqueEntity.orderIndex = Int16(index) // Save the updated order index
            techniqueEntity.isSelected = technique.isSelected
            session.addToSelectedTechniques(techniqueEntity)
        }

        // Save the updated exercises order to the session
        for (index, exercise) in selectedExercises.enumerated() {
            let exerciseEntity = ExerciseEntity(context: context)
            exerciseEntity.id = exercise.id
            exerciseEntity.name = exercise.name
            exerciseEntity.orderIndex = Int16(index) // Save the updated order index
            exerciseEntity.isSelected = exercise.isSelected
            session.addToSelectedExercises(exerciseEntity)
        }

        // Save the updated blocks order to the session
        for (index, block) in selectedBlocks.enumerated() {
            let blockEntity = BlockEntity(context: context)
            blockEntity.id = block.id
            blockEntity.name = block.name
            blockEntity.orderIndex = Int16(index) // Save the updated order index
            blockEntity.isSelected = block.isSelected
            session.addToSelectedBlocks(blockEntity)
        }

        // Save the updated strikes order to the session
        for (index, strike) in selectedStrikes.enumerated() {
            let strikeEntity = StrikeEntity(context: context)
            strikeEntity.id = strike.id
            strikeEntity.name = strike.name
            strikeEntity.orderIndex = Int16(index) // Save the updated order index
            strikeEntity.isSelected = strike.isSelected
            session.addToSelectedStrikes(strikeEntity)
        }
        
        // Save the updated kicks order
        for (index, kick) in selectedKicks.enumerated() {
            let kickEntity = KickEntity(context: context)
            kickEntity.id = kick.id
            kickEntity.name = kick.name
            kickEntity.orderIndex = Int16(index) // Save the updated order index
            kickEntity.isSelected = kick.isSelected
            session.addToSelectedKicks(kickEntity)
        }

        // Save the context
        do {
            try context.save()
            print("Session order saved successfully.")
        } catch {
            print("Failed to save session order: \(error.localizedDescription)")
        }
    }

    
    private func saveSession() {
        print("Saving session: \(sessionName)")
        print("Randomize Techniques: \(randomizeTechniques)")
        print("Time Between Techniques: \(timeBetweenTechniques)")
        print("Selected Techniques: \(selectedTechniques.map { $0.name })")
        print("Selected PracticeType: \(selectedPracticeType)")
        print("Selected Exercises: \(selectedExercises.map { $0.name })")
        print("Selected Blocks: \(selectedBlocks.map { $0.name })")
        print("Selected Strikes: \(selectedStrikes.map { $0.name })")
        print("Selected Katas: \(selectedKatas.map { $0.name })")
        print("Selected Kicks: \(selectedKicks.map { $0.name })")
        print("Set timeForTechniques: \(timeForTechniques)")

        let sessionToSave: TrainingSessionEntity

        if let editingSession = editingSession {
            // Update the existing session's properties
            editingSession.name = sessionName
            editingSession.randomizeTechniques = randomizeTechniques
            editingSession.isFeetTogetherEnabled = isFeetTogetherEnabled
            editingSession.timeBetweenTechniques = Int16(timeBetweenTechniques)
            editingSession.useTimerForTechniques = useTimerForTechniques
            editingSession.useTimerForExercises = useTimerForExercises
            editingSession.useTimerForKatas = useTimerForKatas
            editingSession.useTimerForBlocks = useTimerForBlocks
            editingSession.useTimerForStrikes = useTimerForStrikes
            editingSession.useTimerForKicks = useTimerForKicks
            
            editingSession.timeForKatas = Int16(timeForKatas)
            editingSession.timeForExercises = Int16(timeForExercises)
            editingSession.timeForBlocks = Int16(timeForBlocks)
            editingSession.timeForStrikes = Int16(timeForStrikes)
            editingSession.timeForKicks = Int16(timeForKicks)
            editingSession.timeForTechniques = Int16(timeForTechniques)

            // Clear existing data for techniques, exercises, strikes, and blocks
            editingSession.selectedTechniques = nil
            editingSession.selectedExercises = nil
            editingSession.selectedStrikes = nil
            editingSession.selectedBlocks = nil
            editingSession.selectedKatas = nil
            editingSession.selectedKicks = nil

            sessionToSave = editingSession

        } else {
            // Create a new session
            let newSession = TrainingSessionEntity(context: context)
            newSession.name = sessionName
            newSession.randomizeTechniques = randomizeTechniques
            newSession.isFeetTogetherEnabled = isFeetTogetherEnabled
            newSession.timeBetweenTechniques = Int16(timeBetweenTechniques)
            
            newSession.practiceType = selectedPracticeType.rawValue
            
            newSession.useTimerForTechniques = useTimerForTechniques
            newSession.useTimerForExercises = useTimerForExercises
            newSession.useTimerForKatas = useTimerForKatas
            newSession.useTimerForBlocks = useTimerForBlocks
            newSession.useTimerForStrikes = useTimerForStrikes
            newSession.useTimerForKicks = useTimerForKicks
            
            newSession.timeForKatas = Int16(timeForKatas)
            newSession.timeForExercises = Int16(timeForExercises)
            newSession.timeForBlocks = Int16(timeForBlocks)
            newSession.timeForStrikes = Int16(timeForStrikes)
            newSession.timeForKicks = Int16(timeForKicks)
            newSession.timeForTechniques = Int16(timeForTechniques)
            
            newSession.id = UUID() // Ensure new session has a unique ID

            sessionToSave = newSession
        }

        // Save selected techniques with updated orderIndex and selected status
        // Filter out only selected techniques
        let filteredSelectedTechniques = selectedTechniques.filter { $0.isSelected }
        print("Filtered Selected Techniques: \(filteredSelectedTechniques.map { $0.name })")

        for (index, technique) in filteredSelectedTechniques.enumerated() {
            let techniqueEntity = TechniqueEntity(context: context)
            techniqueEntity.id = technique.id
            techniqueEntity.name = technique.name
            techniqueEntity.beltLevel = technique.beltLevel
            techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
            techniqueEntity.orderIndex = Int16(index)  // This ensures the order is set properly
            techniqueEntity.isSelected = technique.isSelected // Ensure selected state is saved
            sessionToSave.addToSelectedTechniques(techniqueEntity)
            print("Assigned UUID: \(techniqueEntity.id?.uuidString ?? "nil") for technique: \(techniqueEntity.name ?? "Unnamed"), orderIndex: \(index), selected: \(techniqueEntity.isSelected)")
        }

        // Save selected exercises
        let filteredSelectedExercises = selectedExercises.filter { $0.isSelected }
        for (index, exercise) in filteredSelectedExercises.enumerated() {
            let exerciseEntity = ExerciseEntity(context: context)
            exerciseEntity.id = exercise.id
            exerciseEntity.name = exercise.name
            exerciseEntity.orderIndex = Int16(index)
            sessionToSave.addToSelectedExercises(exerciseEntity)
            print("Assigned UUID: \(exerciseEntity.id?.uuidString ?? "nil") for exercise: \(exerciseEntity.name ?? "Unnamed"), orderIndex: \(index), selected: \(exerciseEntity.isSelected)")
        }
        // Save Blocks - similar to exercises, with orderIndex and isSelected
        let filteredSelectedBlocks = selectedBlocks.filter { $0.isSelected }
        for (index, block) in filteredSelectedBlocks.enumerated() {
            let blockEntity = BlockEntity(context: context)
            blockEntity.id = block.id
            blockEntity.name = block.name
            blockEntity.orderIndex = Int16(index) // Save the updated order index
            blockEntity.isSelected = block.isSelected // Ensure selected state is saved
            sessionToSave.addToSelectedBlocks(blockEntity)
            print("Assigned UUID: \(blockEntity.id?.uuidString ?? "nil") for block: \(blockEntity.name ?? "Unnamed"), orderIndex: \(index), selected: \(blockEntity.isSelected)")
        }

        // Save Strikes - similar to blocks
        let filteredSelectedStrikes = selectedStrikes.filter { $0.isSelected }
        for (index, strike) in filteredSelectedStrikes.enumerated() {
            let strikeEntity = StrikeEntity(context: context)
            strikeEntity.id = strike.id
            strikeEntity.name = strike.name
            strikeEntity.orderIndex = Int16(index) // Save the updated order index
            strikeEntity.isSelected = strike.isSelected // Ensure selected state is saved
            sessionToSave.addToSelectedStrikes(strikeEntity)
            print("Assigned UUID: \(strikeEntity.id?.uuidString ?? "nil") for strike: \(strikeEntity.name ?? "Unnamed"), orderIndex: \(index), selected: \(strikeEntity.isSelected)")
        }

        // Save Katas
        let filteredSelectedKatas = selectedKatas.filter { $0.isSelected }
        for (index, kata) in filteredSelectedKatas.enumerated() {
            let kataEntity = KataEntity(context: context)
            kataEntity.id = kata.id
            kataEntity.name = kata.name
            kataEntity.kataNumber = Int16(kata.kataNumber)
            kataEntity.orderIndex = Int16(index)
            kataEntity.isSelected = kata.isSelected
            sessionToSave.addToSelectedKatas(kataEntity)
            print("Assigned UUID: \(kataEntity.id?.uuidString ?? "nil") for kata: \(kataEntity.name ?? "Unnamed"), orderIndex: \(index), selected: \(kataEntity.isSelected)")
        }
        // Save selected kicks
        let filteredSelectedKicks = selectedKicks.filter { $0.isSelected }
        print("Filtered selected kicks for saving: \(filteredSelectedKicks.map { $0.name })")
        for (index, kick) in filteredSelectedKicks.enumerated() {
            let kickEntity = KickEntity(context: context)
            kickEntity.id = kick.id
            kickEntity.name = kick.name
            kickEntity.orderIndex = Int16(index)
            kickEntity.isSelected = kick.isSelected
            sessionToSave.addToSelectedKicks(kickEntity)
            print("Saved kick: \(kick.name), ID: \(kick.id), Selected: \(kick.isSelected), OrderIndex: \(index)")
        }

        
        // Save the context and handle any errors
        do {
            try context.save()
            print("Session saved successfully.")

            // Refresh the list of sessions
            // Force refresh training sessions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dataManager.fetchTrainingSessions()
            }

           // Delay dismissal slightly to ensure UI updates first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                presentationMode.wrappedValue.dismiss()
            }
            
            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
            print("View dismissed successfully.")
        } catch let error as NSError {
            print("Failed to save session: \(error.localizedDescription)")
            if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for detailedError in detailedErrors {
                    print("Detailed Error: \(detailedError), \(detailedError.userInfo)")
                }
            } else {
                print("Error Info: \(error.userInfo)")
            }
        }
    }


    private func loadSessionData(_ session: TrainingSessionEntity) {
        print("Loading session data for session: \(session.name ?? "Unnamed Session")")

        sessionName = session.name ?? ""
        randomizeTechniques = session.randomizeTechniques
        isFeetTogetherEnabled = session.isFeetTogetherEnabled
        if let practiceType = session.practiceType {
            selectedPracticeType = PracticeType(rawValue: practiceType) ?? .soundOff
        }
        timeBetweenTechniques = Int(session.timeBetweenTechniques)
        useTimerForTechniques = session.useTimerForTechniques
        useTimerForExercises = session.useTimerForExercises
        useTimerForKatas = session.useTimerForKatas
        useTimerForBlocks = session.useTimerForBlocks
        useTimerForStrikes = session.useTimerForStrikes
        useTimerForKicks = session.useTimerForKicks
        
        timeForKatas = Int(session.timeForKatas)
        timeForExercises = Int(session.timeForExercises)
        timeForBlocks = Int(session.timeForBlocks)
        timeForStrikes = Int(session.timeForStrikes)
        timeForKicks = Int(session.timeForKicks)
        timeForTechniques = Int(session.timeForTechniques)

        // Reset selected data and populate from the session
        selectedTechniques.removeAll()
        selectedExercises.removeAll()
        selectedBlocks.removeAll()
        selectedStrikes.removeAll()
        selectedKatas.removeAll()
        selectedKicks.removeAll()

        //
        // Load techniques and sort them by orderIndex
        //
        if let techniques = session.selectedTechniques as? Set<TechniqueEntity> {
            let sortedTechniques = techniques.sorted { $0.orderIndex < $1.orderIndex }
            for techniqueEntity in sortedTechniques {
                if let matchingTechnique = predefinedTechniques.first(where: { $0.id == techniqueEntity.id }) {
                    var technique = matchingTechnique
                    technique.isSelected = true // Mark this technique as selected
                    technique.orderIndex = Int(techniqueEntity.orderIndex) // Ensure orderIndex is loaded
                    selectedTechniques.append(technique)
                } else {
                    print("Could not find a matching predefined technique for ID: \(techniqueEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined techniques are in the list, even if not selected
        for predefinedTechnique in predefinedTechniques where !selectedTechniques.contains(where: { $0.id == predefinedTechnique.id }) {
            var technique = predefinedTechnique
            technique.isSelected = false // Mark as not selected
            selectedTechniques.append(technique)
        }

        print("Selected Techniques for editing session (in order): \(selectedTechniques.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load exercises and sort them by orderIndex
        //
        if let exercises = session.selectedExercises as? Set<ExerciseEntity> {
            let sortedExercises = exercises.sorted { $0.orderIndex < $1.orderIndex }
            for exerciseEntity in sortedExercises {
                if let matchingExercise = predefinedExercises.first(where: { $0.id == exerciseEntity.id }) {
                    var exercise = matchingExercise
                    exercise.isSelected = true // Mark this exercise as selected
                    exercise.orderIndex = Int(exerciseEntity.orderIndex) // Ensure orderIndex is loaded
                    selectedExercises.append(exercise)
                } else {
                    print("Could not find a matching predefined exercise for ID: \(exerciseEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined exercises are in the list, even if not selected
        for predefinedExercise in predefinedExercises where !selectedExercises.contains(where: { $0.id == predefinedExercise.id }) {
            var exercise = predefinedExercise
            exercise.isSelected = false // Mark as not selected
            selectedExercises.append(exercise)
        }

        print("Selected Exercises for editing session (in order): \(selectedExercises.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load blocks and sort them by orderIndex
        //
        if let blocks = session.selectedBlocks as? Set<BlockEntity> {
            let sortedBlocks = blocks.sorted { $0.orderIndex < $1.orderIndex }
            for blockEntity in sortedBlocks {
                if let matchingBlock = predefinedBlocks.first(where: { $0.id == blockEntity.id }) {
                    var block = matchingBlock
                    block.isSelected = true
                    block.orderIndex = Int(blockEntity.orderIndex)
                    selectedBlocks.append(block)
                } else {
                    print("Could not find a matching predefined block for ID: \(blockEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined blocks are in the list, even if not selected
        for predefinedBlock in predefinedBlocks where !selectedBlocks.contains(where: { $0.id == predefinedBlock.id }) {
            var block = predefinedBlock
            block.isSelected = false
            selectedBlocks.append(block)
        }

        print("Selected Blocks for editing session (in order): \(selectedBlocks.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load strikes and sort them by orderIndex
        //
        if let strikes = session.selectedStrikes as? Set<StrikeEntity> {
            let sortedStrikes = strikes.sorted { $0.orderIndex < $1.orderIndex }
            for strikeEntity in sortedStrikes {
                if let matchingStrike = predefinedStrikes.first(where: { $0.id == strikeEntity.id }) {
                    var strike = matchingStrike
                    strike.isSelected = true
                    strike.orderIndex = Int(strikeEntity.orderIndex)
                    selectedStrikes.append(strike)
                } else {
                    print("Could not find a matching predefined strike for ID: \(strikeEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure that all predefined strikes are in the list, even if not selected
        for predefinedStrike in predefinedStrikes where !selectedStrikes.contains(where: { $0.id == predefinedStrike.id }) {
            var strike = predefinedStrike
            strike.isSelected = false
            selectedStrikes.append(strike)
        }

        print("Selected Strikes for editing session (in order): \(selectedStrikes.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")

        //
        // Load katas and log them
        //
        if let katas = session.selectedKatas as? Set<KataEntity> {
            let sortedKatas = katas.sorted { $0.orderIndex < $1.orderIndex }
            for kataEntity in sortedKatas {
                if let matchingKata = predefinedKatas.first(where: { $0.id == kataEntity.id }) {
                    var kata = matchingKata
                    kata.isSelected = true // Mark as selected
                    kata.orderIndex = Int(kataEntity.orderIndex) // Ensure orderIndex is loaded
                    selectedKatas.append(kata)
                } else {
                    print("Could not find a matching predefined kata for ID: \(kataEntity.id?.uuidString ?? "nil")")
                }
            }
        }
        // Ensure that all predefined strikes are in the list, even if not selected
        for predefinedKata in predefinedKatas where !selectedKatas.contains(where: { $0.id == predefinedKata.id }) {
            var kata = predefinedKata
            kata.isSelected = false
            selectedKatas.append(kata)
        }
        // Log the selected katas
        print("Selected Katas for editing session: \(selectedKatas.map { $0.name })")
        
        
        // Load selected kicks from the session
        if let kicks = session.selectedKicks as? Set<KickEntity> {
            let sortedKicks = kicks.sorted { $0.orderIndex < $1.orderIndex }
            for kickEntity in sortedKicks {
                if let matchingKick = predefinedKicks.first(where: { $0.id == kickEntity.id }) {
                    var kick = matchingKick
                    kick.isSelected = true // Mark the predefined kick as selected
                    kick.orderIndex = Int(kickEntity.orderIndex)
                    selectedKicks.append(kick)
                    print("Loaded selected kick: \(kick.name), ID: \(kick.id), OrderIndex: \(kick.orderIndex)")
                } else {
                    print("Could not find a matching predefined kick for ID: \(kickEntity.id?.uuidString ?? "nil")")
                }
            }
        }

        // Ensure all predefined kicks are included, even if not selected
        for predefinedKick in predefinedKicks where !selectedKicks.contains(where: { $0.id == predefinedKick.id }) {
            var unselectedKick = predefinedKick
            unselectedKick.isSelected = false // Mark as unselected
            selectedKicks.append(unselectedKick)
            print("Added unselected predefined kick: \(unselectedKick.name), ID: \(unselectedKick.id)")
        }

        // Sort the kicks by orderIndex
        selectedKicks.sort { $0.orderIndex < $1.orderIndex }
        print("Selected Kicks for editing session: \(selectedKicks.map { "\($0.name) - selected: \($0.isSelected)" })")
    }


}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
