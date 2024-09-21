//
//  ContentView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: TrainingSessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrainingSessionEntity.name, ascending: true)]
    ) private var trainingSessions: FetchedResults<TrainingSessionEntity>

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
                                destination: StartTrainingView(
                                    session: convertToTrainingSession(from: session)
                                )
                            ) {
                                VStack(alignment: .leading) {
                                    Text(session.name ?? "Unnamed Session")
                                        .font(.headline)
                                    Text("Techniques: \(session.selectedTechniques?.count ?? 0)")
                                    Text("Exercises: \(session.selectedExercises?.count ?? 0)")
                                    Text("Katas: \(session.selectedKatas?.count ?? 0)")
                                }
                            }
                        }
                        .onDelete(perform: deleteSession)
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Add a button to create a test session
                Button(action: addTestSession) {
                    Text("Add Test Session")
                        .font(.title)
                        .padding()
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
        }
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
