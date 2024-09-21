//
//  CreateTrainingSessionView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI

struct CreateTrainingSessionView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var sessionName: String = ""
    
    // Use predefined lists of techniques, exercises, and katas
    let techniques = predefinedTechniques
    let exercises = predefinedExercises
    let katas = predefinedKatas

    // Track selected items
    @State private var selectedTechniques: Set<Technique> = []
    @State private var selectedExercises: Set<Exercise> = []
    @State private var selectedKatas: Set<Kata> = []

    var body: some View {
        Form {
            Section(header: Text("Session Name")) {
                TextField("Enter session name", text: $sessionName)
            }

            Section(header: Text("Select Techniques")) {
                List(techniques, id: \.name) { technique in
                    MultipleSelectionRow(title: technique.name, isSelected: selectedTechniques.contains(technique)) {
                        if selectedTechniques.contains(technique) {
                            selectedTechniques.remove(technique)
                        } else {
                            selectedTechniques.insert(technique)
                        }
                    }
                }
            }

            Section(header: Text("Select Exercises")) {
                List(exercises, id: \.name) { exercise in
                    MultipleSelectionRow(title: exercise.name, isSelected: selectedExercises.contains(exercise)) {
                        if selectedExercises.contains(exercise) {
                            selectedExercises.remove(exercise)
                        } else {
                            selectedExercises.insert(exercise)
                        }
                    }
                }
            }

            Section(header: Text("Select Katas")) {
                List(katas, id: \.name) { kata in
                    MultipleSelectionRow(title: kata.name, isSelected: selectedKatas.contains(kata)) {
                        if selectedKatas.contains(kata) {
                            selectedKatas.remove(kata)
                        } else {
                            selectedKatas.insert(kata)
                        }
                    }
                }
            }

            Button(action: saveTrainingSession) {
                Text("Save Session")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            .disabled(sessionName.isEmpty || (selectedTechniques.isEmpty && selectedExercises.isEmpty && selectedKatas.isEmpty))
        }
        .navigationTitle("Create Training Session")
    }

    // Function to save the training session to Core Data
    private func saveTrainingSession() {
        let newSession = TrainingSessionEntity(context: context)
        newSession.name = sessionName
        newSession.timeBetweenTechniques = 5
        newSession.randomizeTechniques = false
        newSession.isFeetTogetherEnabled = true

        // Add selected techniques to the session's techniques relationship
        selectedTechniques.forEach { technique in
            let techniqueEntity = TechniqueEntity(context: context)
            techniqueEntity.name = technique.name
            techniqueEntity.beltLevel = technique.beltLevel
            techniqueEntity.timeToComplete = Int16(technique.timeToComplete)
            newSession.addToSelectedTechniques(techniqueEntity)
        }

        // Add selected exercises and katas to the session
        selectedExercises.forEach { exercise in
            let exerciseEntity = ExerciseEntity(context: context)
            exerciseEntity.name = exercise.name
            newSession.addToSelectedExercises(exerciseEntity)
        }

        selectedKatas.forEach { kata in
            let kataEntity = KataEntity(context: context)
            kataEntity.name = kata.name
            kataEntity.kataNumber = Int16(kata.kataNumber)
            newSession.addToSelectedKatas(kataEntity)
        }

        do {
            try context.save()
        } catch {
            print("Failed to save session: \(error.localizedDescription)")
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
