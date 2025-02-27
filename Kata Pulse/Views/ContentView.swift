//
//  ContentView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: TrainingSessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TrainingSessionEntity.name, ascending: true)]
    ) private var trainingSessions: FetchedResults<TrainingSessionEntity>

    @State private var showCreateView = false
    @State private var showEditView = false
    @State private var selectedSession: TrainingSessionEntity? // For editing

    var body: some View {
        TabView {
            // Sessions Tab
            SessionsTab(
                trainingSessions: dataManager.trainingSessions,
                dataManager: dataManager,
                showCreateView: $showCreateView,
                showEditView: $showEditView,
                selectedSession: $selectedSession
            )
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet")
                }

            // History Tab
            HistoryTab()
                .tabItem {
                        Label("History", systemImage: "clock")
                    }
            
            // Statistics Tab
            StatisticsTab()
                .tabItem {
                        Label("Statistics", systemImage: "chart.bar")
                    }
            
            // Global Settings Tab
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
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
                beltLevel: BeltLevel(rawValue: techniqueEntity.beltLevel ?? "Unknown") ?? .unknown, // ✅ Fixed conversion
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
        
        let blocksArray: [Block] = (entity.selectedBlocks?.allObjects as? [BlockEntity])?.map { blockEntity in
            Block(
                name: blockEntity.name ?? "Unnamed"
            )
        } ?? []
        
        let strikesArray: [Strike] = (entity.selectedStrikes?.allObjects as? [StrikeEntity])?.map { strikeEntity in
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

        let kicksArray: [Kick] = (entity.selectedKicks?.allObjects as? [KickEntity])?.map { kickEntity in
            Kick(
                name: kickEntity.name ?? "Unnamed"
            )
        } ?? []

        // Ensure the UUID is retrieved from the entity's id or create a new one if not found
        let sessionId = entity.id ?? UUID()
        
        // Safely map the Core Data `practiceType` string to the `PracticeType` enum
        let practiceType = PracticeType(rawValue: entity.practiceType ?? PracticeType.soundOff.rawValue) ?? .soundOff

        return TrainingSession(
            id: sessionId,
            name: entity.name ?? "Unnamed",
            techniques: techniquesArray,
            practiceType: practiceType,
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
