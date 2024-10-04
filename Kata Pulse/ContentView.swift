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

    @State private var showCreateView = false
    @State private var showEditView = false
    @State private var selectedSession: TrainingSessionEntity? // For editing

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

                                    // Display the counts for each category on a new line
                                    Text("Techniques: \(session.selectedTechniques?.count ?? 0)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Exercises: \(session.selectedExercises?.count ?? 0)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Katas: \(session.selectedKatas?.count ?? 0)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Blocks: \(session.selectedBlocks?.count ?? 0)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Strikes: \(session.selectedStrikes?.count ?? 0)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Kicks: \(session.selectedKicks?.count ?? 0)")
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
                    Button {
                        showCreateView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Sheet for creating a new session
            .sheet(isPresented: $showCreateView) {
                CreateTrainingSessionView()
            }
            // Sheet for editing an existing session
            .sheet(isPresented: $showEditView) {
                if let selectedSession = selectedSession {
                    CreateTrainingSessionView(editingSession: selectedSession)
                }
            }
            // This modifier tracks changes to selectedSession
            .onChange(of: selectedSession) {
                print("Selected session for editing: \(selectedSession?.name ?? "Unknown")")
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
        
        let blocksArray: [Block] = (entity.selectedBlocks?.allObjects as? [BlockEntity])?.map { BlockEntity in
            Block(
                name: BlockEntity.name ?? "Unnamed"
            )
        } ?? []
        
        let strikesArray: [Strike] = (entity.selectedStrikes?.allObjects as? [StrikeEntity])?.map { StrikeEntity in
            Strike(
                name: StrikeEntity.name ?? "Unnamed"
            )
        } ?? []

        let kicksArray: [Kick] = (entity.selectedKicks?.allObjects as? [KickEntity])?.map { KickEntity in
            Kick(
                name: KickEntity.name ?? "Unnamed"
            )
        } ?? []

        // Ensure the UUID is retrieved from the entity's id or create a new one if not found
        let sessionId = entity.id ?? UUID()

        return TrainingSession(
            id: sessionId,
            name: entity.name ?? "Unnamed",
            techniques: techniquesArray,
            exercises: exercisesArray,
            katas: katasArray,
            blocks: blocksArray,
            strikes: strikesArray,
            kicks: kicksArray,
            timeBetweenTechniques: Int(entity.timeBetweenTechniques),
            randomizeTechniques: entity.randomizeTechniques,
            isFeetTogetherEnabled: entity.isFeetTogetherEnabled
        )
    }
}
