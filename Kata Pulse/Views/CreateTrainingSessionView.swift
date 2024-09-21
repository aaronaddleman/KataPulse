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
    @State private var selectedBlocks: [Block] = [] // New Blocks selection
    @State private var selectedStrikes: [Strike] = [] // New Strikes selection
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

            Section(header: Text("Techniques")) {
                List {
                    ForEach(predefinedTechniques, id: \.self) { technique in
                        HStack {
                            Text(technique.name)
                            Spacer()
                            if selectedTechniques.contains(technique) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleTechniqueSelection(technique)
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedTechniques.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .environment(\.editMode, .constant(.active)) // Enable reordering
            }

            Section(header: Text("Exercises")) {
                List {
                    ForEach(predefinedExercises, id: \.self) { exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            if selectedExercises.contains(exercise) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleExerciseSelection(exercise)
                        }
                    }
                    .onMove { indices, newOffset in
                        selectedExercises.move(fromOffsets: indices, toOffset: newOffset)
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
                loadSessionData(session)
            }
        }
    }

    private func toggleTechniqueSelection(_ technique: Technique) {
        if let index = selectedTechniques.firstIndex(of: technique) {
            selectedTechniques.remove(at: index) // Deselect if already selected
        } else {
            selectedTechniques.append(technique) // Select if not already selected
        }
    }

    private func toggleExerciseSelection(_ exercise: Exercise) {
        if let index = selectedExercises.firstIndex(of: exercise) {
            selectedExercises.remove(at: index) // Deselect
        } else {
            selectedExercises.append(exercise) // Select
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

    private func saveSession() {
        // Check if we're editing an existing session or creating a new one
        if let editingSession = editingSession {
            // Update the existing session's properties
            editingSession.name = sessionName
            editingSession.randomizeTechniques = randomizeTechniques
            editingSession.isFeetTogetherEnabled = isFeetTogetherEnabled
            editingSession.timeBetweenTechniques = Int16(timeBetweenTechniques)

            // Clear existing techniques, exercises, katas, blocks, and strikes
            editingSession.selectedTechniques = nil
            editingSession.selectedExercises = nil
            editingSession.selectedKatas = nil
            editingSession.selectedBlocks = nil
            editingSession.selectedStrikes = nil

            // Add updated selections
            for technique in selectedTechniques {
                let techniqueEntity = TechniqueEntity(context: context)
                techniqueEntity.name = technique.name
                techniqueEntity.beltLevel = technique.beltLevel
                techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
                editingSession.addToSelectedTechniques(techniqueEntity)
            }

            for exercise in selectedExercises {
                let exerciseEntity = ExerciseEntity(context: context)
                exerciseEntity.name = exercise.name
                editingSession.addToSelectedExercises(exerciseEntity)
            }

            for kata in selectedKatas {
                let kataEntity = KataEntity(context: context)
                kataEntity.name = kata.name
                kataEntity.kataNumber = Int16(kata.kataNumber)
                editingSession.addToSelectedKatas(kataEntity)
            }

            for block in selectedBlocks {
                let blockEntity = BlockEntity(context: context)
                blockEntity.name = block.name
                editingSession.addToSelectedBlocks(blockEntity)
            }

            for strike in selectedStrikes {
                let strikeEntity = StrikeEntity(context: context)
                strikeEntity.name = strike.name
                editingSession.addToSelectedStrikes(strikeEntity)
            }
        } else {
            // Creating a new session
            let newSession = TrainingSessionEntity(context: context)
            newSession.name = sessionName
            newSession.randomizeTechniques = randomizeTechniques
            newSession.isFeetTogetherEnabled = isFeetTogetherEnabled
            newSession.timeBetweenTechniques = Int16(timeBetweenTechniques)

            // Add techniques, exercises, katas, blocks, and strikes to the new session
            for technique in selectedTechniques {
                let techniqueEntity = TechniqueEntity(context: context)
                techniqueEntity.name = technique.name
                techniqueEntity.beltLevel = technique.beltLevel
                techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
                newSession.addToSelectedTechniques(techniqueEntity)
            }

            for exercise in selectedExercises {
                let exerciseEntity = ExerciseEntity(context: context)
                exerciseEntity.name = exercise.name
                newSession.addToSelectedExercises(exerciseEntity)
            }

            for kata in selectedKatas {
                let kataEntity = KataEntity(context: context)
                kataEntity.name = kata.name
                kataEntity.kataNumber = Int16(kata.kataNumber)
                newSession.addToSelectedKatas(kataEntity)
            }

            for block in selectedBlocks {
                let blockEntity = BlockEntity(context: context)
                blockEntity.name = block.name
                newSession.addToSelectedBlocks(blockEntity)
            }

            for strike in selectedStrikes {
                let strikeEntity = StrikeEntity(context: context)
                strikeEntity.name = strike.name
                newSession.addToSelectedStrikes(strikeEntity)
            }
        }

        // Save the context to persist changes
        do {
            try context.save()
            print("Session saved successfully.")
            presentationMode.wrappedValue.dismiss() // Dismiss the view after saving
        } catch {
            print("Failed to save session: \(error.localizedDescription)")
        }
    }

    private func loadSessionData(_ session: TrainingSessionEntity) {
        sessionName = session.name ?? ""
        randomizeTechniques = session.randomizeTechniques
        isFeetTogetherEnabled = session.isFeetTogetherEnabled
        timeBetweenTechniques = Int(session.timeBetweenTechniques)

        if let techniques = session.selectedTechniques as? Set<TechniqueEntity> {
            selectedTechniques = techniques.map { Technique(name: $0.name ?? "Unnamed", beltLevel: $0.beltLevel ?? "Unknown", timeToComplete: Int($0.timeToComplete)) }
        }

        if let exercises = session.selectedExercises as? Set<ExerciseEntity> {
            selectedExercises = exercises.map { Exercise(name: $0.name ?? "Unnamed") }
        }

        if let katas = session.selectedKatas as? Set<KataEntity> {
            selectedKatas = katas.map { Kata(name: $0.name ?? "Unnamed", kataNumber: Int($0.kataNumber)) }
        }

        // Load Blocks
        if let blocks = session.selectedBlocks as? Set<BlockEntity> {
            selectedBlocks = blocks.map { Block(name: $0.name ?? "Unnamed") }
        }

        // Load Strikes
        if let strikes = session.selectedStrikes as? Set<StrikeEntity> {
            selectedStrikes = strikes.map { Strike(name: $0.name ?? "Unnamed") }
        }
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
