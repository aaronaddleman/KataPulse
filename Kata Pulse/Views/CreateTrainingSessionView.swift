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

    var editingSession: TrainingSessionEntity? // Optional session for editing

    @State private var sessionName: String = ""
    @State private var selectedTechniques: Set<Technique> = []
    @State private var selectedExercises: Set<Exercise> = []
    @State private var selectedKatas: Set<Kata> = []
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
            }

            Section(header: Text("Exercises")) {
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
            }

            Section(header: Text("Katas")) {
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
        if selectedTechniques.contains(technique) {
            selectedTechniques.remove(technique)
        } else {
            selectedTechniques.insert(technique)
        }
    }

    private func toggleExerciseSelection(_ exercise: Exercise) {
        if selectedExercises.contains(exercise) {
            selectedExercises.remove(exercise)
        } else {
            selectedExercises.insert(exercise)
        }
    }

    private func toggleKataSelection(_ kata: Kata) {
        if selectedKatas.contains(kata) {
            selectedKatas.remove(kata)
        } else {
            selectedKatas.insert(kata)
        }
    }

    // Load session data for editing
    private func loadSessionData(_ session: TrainingSessionEntity) {
        sessionName = session.name ?? ""
        randomizeTechniques = session.randomizeTechniques
        isFeetTogetherEnabled = session.isFeetTogetherEnabled
        timeBetweenTechniques = Int(session.timeBetweenTechniques)

        if let techniques = session.selectedTechniques as? Set<TechniqueEntity> {
            selectedTechniques = Set(techniques.map { Technique(from: $0) })
        }

        if let exercises = session.selectedExercises as? Set<ExerciseEntity> {
            selectedExercises = Set(exercises.map { Exercise(from: $0) })
        }

        if let katas = session.selectedKatas as? Set<KataEntity> {
            selectedKatas = Set(katas.map { Kata(from: $0) })
        }
    }

    // Save session data (create or edit)
    private func saveSession() {
        if let session = editingSession {
            // Update existing session
            session.name = sessionName
            session.randomizeTechniques = randomizeTechniques
            session.isFeetTogetherEnabled = isFeetTogetherEnabled
            session.timeBetweenTechniques = Int16(timeBetweenTechniques)

            session.selectedTechniques = NSSet(array: selectedTechniques.map { $0.toEntity(context: context) })
            session.selectedExercises = NSSet(array: selectedExercises.map { $0.toEntity(context: context) })
            session.selectedKatas = NSSet(array: selectedKatas.map { $0.toEntity(context: context) })
        } else {
            // Create new session
            let newSession = TrainingSessionEntity(context: context)
            newSession.name = sessionName
            newSession.randomizeTechniques = randomizeTechniques
            newSession.isFeetTogetherEnabled = isFeetTogetherEnabled
            newSession.timeBetweenTechniques = Int16(timeBetweenTechniques)

            newSession.selectedTechniques = NSSet(array: selectedTechniques.map { $0.toEntity(context: context) })
            newSession.selectedExercises = NSSet(array: selectedExercises.map { $0.toEntity(context: context) })
            newSession.selectedKatas = NSSet(array: selectedKatas.map { $0.toEntity(context: context) })
        }

        do {
            try context.save()
            presentationMode.wrappedValue.dismiss()
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
