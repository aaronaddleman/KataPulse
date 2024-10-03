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

    var editingSession: TrainingSessionEntity?

    @State private var sessionName: String = ""
    @State private var selectedTechniques: [Technique] = []
    @State private var selectedExercises: [Exercise] = []
    @State private var selectedKatas: [Kata] = []
    @State private var selectedBlocks: [Block] = []
    @State private var selectedStrikes: [Strike] = []
    @State private var randomizeTechniques: Bool = false
    @State private var isFeetTogetherEnabled: Bool = false
    @State private var timeBetweenTechniques: Int = 5

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

                Stepper("Time Between Techniques: \(timeBetweenTechniques) seconds", value: $timeBetweenTechniques, in: 1...30)
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
                    ForEach(predefinedKatas, id: \.self) { kata in
                        HStack {
                            Text(kata.name)
                            Spacer()
                            if selectedKatas.contains(kata) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleKataSelection(kata)
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedKatas.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            Section(header: Text("Blocks")) {
                List {
                    ForEach(predefinedBlocks, id: \.self) { block in
                        HStack {
                            Text(block.name)
                            Spacer()
                            if selectedBlocks.contains(block) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleBlockSelection(block)
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedBlocks.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            Section(header: Text("Strikes")) {
                List {
                    ForEach(predefinedStrikes, id: \.self) { strike in
                        HStack {
                            Text(strike.name)
                            Spacer()
                            if selectedStrikes.contains(strike) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleStrikeSelection(strike)
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedStrikes.move(fromOffsets: indices, toOffset: newOffset)
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
            if let session = editingSession {
                // Load session data for editing
                loadSessionData(session)
            } else {
                // New session, ensure all predefined techniques are displayed
                selectedTechniques = predefinedTechniques
                // New session, ensure all predefined exercises are displayed
                selectedExercises = predefinedExercises
            }
        }
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
    
    private func toggleKataSelection(_ kata: Kata) {
        if let index = selectedKatas.firstIndex(of: kata) {
            selectedKatas.remove(at: index) // Deselect
        } else {
            selectedKatas.append(kata) // Select
        }
    }

    private func toggleBlockSelection(_ block: Block) {
        if let index = selectedBlocks.firstIndex(of: block) {
            selectedBlocks.remove(at: index) // Deselect
        } else {
            selectedBlocks.append(block) // Select
        }
    }

    private func toggleStrikeSelection(_ strike: Strike) {
        if let index = selectedStrikes.firstIndex(of: strike) {
            selectedStrikes.remove(at: index) // Deselect
        } else {
            selectedStrikes.append(strike) // Select
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
        
        // Clear existing selected techniques
        session.selectedTechniques = nil
        
        // Save the updated techniques order to the session
        for (index, technique) in selectedTechniques.enumerated() {
            let techniqueEntity = TechniqueEntity(context: context)
            techniqueEntity.id = technique.id
            techniqueEntity.name = technique.name
            techniqueEntity.beltLevel = technique.beltLevel
            techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
            techniqueEntity.orderIndex = Int16(index) // Save the updated order index
            session.addToSelectedTechniques(techniqueEntity)
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
        print("Selected Exercises: \(selectedExercises.map { $0.name })")
        print("Selected Blocks: \(selectedBlocks.map { $0.name })")
        print("Selected Strikes: \(selectedStrikes.map { $0.name })")


        let sessionToSave: TrainingSessionEntity

        if let editingSession = editingSession {
            // Update the existing session's properties
            editingSession.name = sessionName
            editingSession.randomizeTechniques = randomizeTechniques
            editingSession.isFeetTogetherEnabled = isFeetTogetherEnabled
            editingSession.timeBetweenTechniques = Int16(timeBetweenTechniques)

            // Clear existing data for techniques, exercises, strikes, and blocks
            editingSession.selectedTechniques = nil
            editingSession.selectedExercises = nil
            editingSession.selectedStrikes = nil
            editingSession.selectedBlocks = nil
            editingSession.selectedKatas = nil

            sessionToSave = editingSession

        } else {
            // Create a new session
            let newSession = TrainingSessionEntity(context: context)
            newSession.name = sessionName
            newSession.randomizeTechniques = randomizeTechniques
            newSession.isFeetTogetherEnabled = isFeetTogetherEnabled
            newSession.timeBetweenTechniques = Int16(timeBetweenTechniques)
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

        // Save Exercises
        let filteredSelectedExercises = selectedExercises.filter { $0.isSelected }
        for (index, exercise) in filteredSelectedExercises.enumerated() {
            let exerciseEntity = ExerciseEntity(context: context)
            exerciseEntity.id = exercise.id
            exerciseEntity.name = exercise.name
            exerciseEntity.orderIndex = Int16(index)
            exerciseEntity.isSelected = exercise.isSelected
            editingSession?.addToSelectedExercises(exerciseEntity)
            print("Assigned UUID: \(exerciseEntity.id?.uuidString ?? "nil") for exercise: \(exerciseEntity.name ?? "Unnamed"), orderIndex: \(index), selected: \(exerciseEntity.isSelected)")
        }

        // Save Blocks
        for block in selectedBlocks {
            let blockEntity = BlockEntity(context: context)
            blockEntity.name = block.name
            sessionToSave.addToSelectedBlocks(blockEntity)
            print("Saved block: \(blockEntity.name ?? "Unnamed")")
        }

        // Save Strikes
        for strike in selectedStrikes {
            let strikeEntity = StrikeEntity(context: context)
            strikeEntity.name = strike.name
            sessionToSave.addToSelectedStrikes(strikeEntity)
            print("Saved strike: \(strikeEntity.name ?? "Unnamed")")
        }

        // Save Katas
        for kata in selectedKatas {
            let kataEntity = KataEntity(context: context)
            kataEntity.name = kata.name
            kataEntity.kataNumber = Int16(kata.kataNumber)
            sessionToSave.addToSelectedKatas(kataEntity)
        }

        // Save the context and handle any errors
        do {
            try context.save()
            print("Session saved successfully.")
            presentationMode.wrappedValue.dismiss()
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
        timeBetweenTechniques = Int(session.timeBetweenTechniques)

        // Reset selected data and populate from the session
        selectedTechniques.removeAll()
        selectedExercises.removeAll()
        selectedBlocks.removeAll()
        selectedStrikes.removeAll()
        selectedKatas.removeAll()

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

        // Log the selected techniques with orderIndex
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

        // Log the selected exercises with orderIndex
        print("Selected Exercises for editing session (in order): \(selectedExercises.map { "\($0.name) - orderIndex: \($0.orderIndex)" })")


        //
        // Load blocks and log them
        //
        if let blocks = session.selectedBlocks as? Set<BlockEntity> {
            print("Found \(blocks.count) blocks in session.")
            for blockEntity in blocks {
                if let matchingBlock = predefinedBlocks.first(where: { $0.name == blockEntity.name }) {
                    selectedBlocks.append(matchingBlock)
                    print("Loaded block: \(matchingBlock.name) [Should be selected]")
                } else {
                    print("Could not find a matching predefined block for name: \(blockEntity.name ?? "Unnamed")")
                }
            }
        } else {
            print("No blocks found in session.")
        }

        // Log the selected blocks
        print("Selected Blocks for editing session: \(selectedBlocks.map { $0.name })")

        // Load strikes and log them
        if let strikes = session.selectedStrikes as? Set<StrikeEntity> {
            print("Found \(strikes.count) strikes in session.")
            for strikeEntity in strikes {
                if let matchingStrike = predefinedStrikes.first(where: { $0.name == strikeEntity.name }) {
                    selectedStrikes.append(matchingStrike)
                    print("Loaded strike: \(matchingStrike.name) [Should be selected]")
                } else {
                    print("Could not find a matching predefined strike for name: \(strikeEntity.name ?? "Unnamed")")
                }
            }
        } else {
            print("No strikes found in session.")
        }

        // Log the selected strikes
        print("Selected Strikes for editing session: \(selectedStrikes.map { $0.name })")
        
        // Load Katas
        if let katas = session.selectedKatas as? Set<KataEntity> {
            print("Found \(katas.count) katas in session.")
            for kataEntity in katas {
                if let matchingKata = predefinedKatas.first(where: { $0.name == kataEntity.name && $0.kataNumber == Int(kataEntity.kataNumber) }) {
                    selectedKatas.append(matchingKata)
                    print("Loaded kata: \(matchingKata.name) [Should be selected]")
                } else {
                    print("Could not find a matching predefined kata for name: \(kataEntity.name ?? "Unnamed")")
                }
            }
        } else {
            print("No katas found in session.")
        }

        // Log the selected katas
        print("Selected Katas for editing session: \(selectedKatas.map { $0.name })")
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
