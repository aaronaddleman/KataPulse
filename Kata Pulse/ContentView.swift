//
//  ContentView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import CoreData

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: TrainingSessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrainingSessionEntity.name, ascending: true)]
    ) private var trainingSessions: FetchedResults<TrainingSessionEntity>

    @State private var showEditView: Bool = false
    @State private var selectedSession: TrainingSessionEntity? // For passing the selected session to the edit view

    var body: some View {
        NavigationView {
            VStack {
                if trainingSessions.isEmpty {
                    Text("No training sessions available.")
                        .font(.headline)
                        .padding()
                } else {
                    List {
                        ForEach(trainingSessions, id: \.self) { session in
                            NavigationLink(
                                destination: StartTrainingView(session: convertToTrainingSession(from: session))
                            ) {
                                VStack(alignment: .leading) {
                                    Text(session.name ?? "Unnamed Session")
                                        .font(.headline)
                                        .padding(.vertical, 2)

                                    HStack {
                                        Text("Techniques: \(session.selectedTechniques?.count ?? 0)")
                                        Text("Exercises: \(session.selectedExercises?.count ?? 0)")
                                        Text("Katas: \(session.selectedKatas?.count ?? 0)")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteSession(session: session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    selectedSession = session
                                    showEditView = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Kata Pulse")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateTrainingSessionView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            // Navigation to Edit View when swipe to edit is triggered
            .sheet(isPresented: $showEditView) {
                if let selectedSession = selectedSession {
                    CreateTrainingSessionView(editingSession: selectedSession)
                }
            }
        }
    }

    // Function to handle session deletion
    private func deleteSession(session: TrainingSessionEntity) {
        context.delete(session)

        do {
            try context.save()
        } catch {
            print("Failed to delete session: \(error.localizedDescription)")
        }
    }

    // Helper function to convert Core Data entity to TrainingSession model
    private func convertToTrainingSession(from entity: TrainingSessionEntity) -> TrainingSession {
        // Extract techniques from Core Data entities and map them to Technique model
        let techniquesArray: [Technique] = (entity.selectedTechniques?.allObjects as? [TechniqueEntity])?.map { techniqueEntity in
            Technique(
                name: techniqueEntity.name ?? "Unnamed",
                beltLevel: techniqueEntity.beltLevel ?? "Unknown",
                timeToComplete: Int(techniqueEntity.timeToComplete)
            )
        } ?? []

        let exercisesArray: [Exercise] = (entity.selectedExercises?.allObjects as? [ExerciseEntity])?.map { exerciseEntity in
            Exercise(name: exerciseEntity.name ?? "Unnamed")
        } ?? []

        let katasArray: [Kata] = (entity.selectedKatas?.allObjects as? [KataEntity])?.map { kataEntity in
            Kata(
                name: kataEntity.name ?? "Unnamed",
                kataNumber: Int(kataEntity.kataNumber)
            )
        } ?? []

        return TrainingSession(
            name: entity.name ?? "Unnamed",
            techniques: techniquesArray,
            exercises: exercisesArray,
            katas: katasArray,
            timeBetweenTechniques: Int(entity.timeBetweenTechniques),
            randomizeTechniques: entity.randomizeTechniques,
            isFeetTogetherEnabled: entity.isFeetTogetherEnabled
        )
    }

    private func addTestSession() {
        // Create a new training session
        let newSession = TrainingSessionEntity(context: context)
        newSession.name = "Test Session"
        newSession.timeBetweenTechniques = 5
        newSession.randomizeTechniques = false
        newSession.isFeetTogetherEnabled = true
        
        // Create techniques for the session
        let technique1 = TechniqueEntity(context: context)
        technique1.name = "Punch"
        technique1.beltLevel = "White"
        technique1.timeToComplete = 5
        let technique2 = TechniqueEntity(context: context)
        technique2.name = "Kick"
        technique2.beltLevel = "White"
        technique2.timeToComplete = 7
        
        // Associate techniques with the session
        newSession.addToSelectedTechniques(technique1)
        newSession.addToSelectedTechniques(technique2)
        
        // Create exercises for the session
        let exercise1 = ExerciseEntity(context: context)
        exercise1.name = "Pushups"
        let exercise2 = ExerciseEntity(context: context)
        exercise2.name = "Squats"
        
        // Associate exercises with the session
        newSession.addToSelectedExercises(exercise1)
        newSession.addToSelectedExercises(exercise2)
        
        // Create katas for the session
        let kata1 = KataEntity(context: context)
        kata1.name = "Kata 1"
        kata1.kataNumber = 1
        let kata2 = KataEntity(context: context)
        kata2.name = "Kata 2"
        kata2.kataNumber = 2
        
        // Associate katas with the session
        newSession.addToSelectedKatas(kata1)
        newSession.addToSelectedKatas(kata2)
        
        // Save the context to persist the new session and its associations
        do {
            try context.save()
            print("Test session and related entities saved successfully.")
        } catch {
            print("Failed to save test session: \(error.localizedDescription)")
        }
    }


    // Function to handle session deletion
    private func deleteSession(at offsets: IndexSet) {
        for index in offsets {
            let session = trainingSessions[index]
            context.delete(session)
        }

        do {
            try context.save()
        } catch {
            print("Failed to delete session: \(error.localizedDescription)")
        }
    }
}
