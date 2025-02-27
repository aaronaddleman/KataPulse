//
//  DataManager.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/24/25.
//

import Foundation
import CoreData

struct TrainingSessionData {
    var name: String
    var randomizeTechniques: Bool
    var isFeetTogetherEnabled: Bool
    var practiceType: PracticeType
    var timeBetweenTechniques: Int
    var useTimerForTechniques: Bool
    var useTimerForExercises: Bool
    var useTimerForKatas: Bool
    var useTimerForBlocks: Bool
    var useTimerForStrikes: Bool
    var useTimerForKicks: Bool
    var timeForTechniques: Int
    var timeForExercises: Int
    var timeForKatas: Int
    var timeForBlocks: Int
    var timeForStrikes: Int
    var timeForKicks: Int
    var selectedTechniques: [Technique]
    var selectedExercises: [Exercise]
    var selectedBlocks: [Block]
    var selectedStrikes: [Strike]
    var selectedKatas: [Kata]
    var selectedKicks: [Kick]
}


class DataManager: ObservableObject {
    @Published var trainingSessions: [TrainingSessionEntity] = []
    private let context: NSManagedObjectContext
    static let shared = DataManager(persistenceController: PersistenceController.shared)
    @Published var shouldRefresh: Bool = false

    init(persistenceController: PersistenceController) {
            self.context = persistenceController.container.viewContext
    }

    // Fetch training sessions from Core Data
    func fetchTrainingSessions() {
        let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
        
        do {
            let sessions = try context.fetch(request)
            // Load relationships to ensure everything is included
            for session in sessions {
                _ = session.selectedKicks?.count // Force Core Data to fetch the kicks
                _ = session.selectedTechniques?.count
                _ = session.selectedBlocks?.count
                _ = session.selectedStrikes?.count
                _ = session.selectedKatas?.count
                _ = session.selectedExercises?.count
            }
            DispatchQueue.main.async {
                self.trainingSessions = sessions
                self.shouldRefresh.toggle()
            }
            print("Fetched \(sessions.count) training sessions.")
        } catch {
            print("Failed to fetch training sessions: \(error.localizedDescription)")
        }
    }


    // Save changes to Core Data
    func saveContext() {
        do {
            try context.save()
            print("Context saved successfully.")
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    // Add a new training session
    func addTrainingSession(name: String, randomizeTechniques: Bool, timeBetweenTechniques: Int16) {
        let newSession = TrainingSessionEntity(context: context)
        newSession.id = UUID()
        newSession.name = name
        newSession.randomizeTechniques = randomizeTechniques
        newSession.timeBetweenTechniques = timeBetweenTechniques

        saveContext()
        fetchTrainingSessions() // Refresh the list
    }

    // Delete a training session
    func deleteTrainingSession(session: TrainingSessionEntity) {
        context.delete(session)
        saveContext()
        fetchTrainingSessions() // Refresh the list
    }
    
    func getSessionDetails(for id: UUID) -> TrainingSessionEntity? {
        let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
    
    func getTechniques(for sessionId: UUID) -> [Technique] {
        guard let session = getSessionDetails(for: sessionId),
              let techniqueEntities = session.selectedTechniques?.allObjects as? [TechniqueEntity] else {
            return []
        }

        return techniqueEntities.map {
            Technique(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                beltLevel: BeltLevel(rawValue: $0.beltLevel ?? "Unknown") ?? .unknown, // ✅ Fixed conversion
                timeToComplete: Int($0.timeToComplete),
                isSelected: $0.isSelected
            )
        }.sorted(by: { $0.orderIndex < $1.orderIndex })
    }
    
    func fetchTechniques(for session: TrainingSessionEntity) -> [Technique] {
        guard let selectedTechniques = session.selectedTechniques?.allObjects as? [TechniqueEntity] else {
            return []
        }

        return selectedTechniques.map {
            Technique(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                beltLevel: BeltLevel(rawValue: $0.beltLevel ?? "Unknown") ?? .unknown, // ✅ Fixed conversion
                timeToComplete: Int($0.timeToComplete),
                isSelected: $0.isSelected
            )
        }.sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    
    func loadSessionData(_ session: TrainingSessionEntity) -> TrainingSessionData {
        print("Loading data for session: \(session.name ?? "Unnamed Session")")
        
        let sessionData = TrainingSessionData(
            name: session.name ?? "",
            randomizeTechniques: session.randomizeTechniques,
            isFeetTogetherEnabled: session.isFeetTogetherEnabled,
            practiceType: PracticeType(rawValue: session.practiceType ?? "") ?? .soundOff,
            timeBetweenTechniques: Int(session.timeBetweenTechniques),
            useTimerForTechniques: session.useTimerForTechniques,
            useTimerForExercises: session.useTimerForExercises,
            useTimerForKatas: session.useTimerForKatas,
            useTimerForBlocks: session.useTimerForBlocks,
            useTimerForStrikes: session.useTimerForStrikes,
            useTimerForKicks: session.useTimerForKicks,
            timeForTechniques: Int(session.timeForTechniques),
            timeForExercises: Int(session.timeForExercises),
            timeForKatas: Int(session.timeForKatas),
            timeForBlocks: Int(session.timeForBlocks),
            timeForStrikes: Int(session.timeForStrikes),
            timeForKicks: Int(session.timeForKicks),
            selectedTechniques: fetchTechniques(for: session),
            selectedExercises: fetchExercises(for: session),
            selectedBlocks: fetchBlocks(for: session),
            selectedStrikes: fetchStrikes(for: session),
            selectedKatas: fetchKatas(for: session),
            selectedKicks: fetchKicks(for: session)
        )
        print("Loaded session data: \(sessionData)")
        return sessionData
    }
    
    func prepareForNewSession() -> TrainingSessionData {
        let predefinedTechniques = loadPredefinedTechniques()
        let predefinedKicks = loadPredefinedKicks()
        let predefinedExercises = loadPredefinedExercises()
        let predefinedKatas = loadPredefinedKatas()
        let predefinedBlocks = loadPredefinedBlocks()
        let predefinedStrikes = loadPredefinedStrikes()

        return TrainingSessionData(
            name: "",
            randomizeTechniques: false,
            isFeetTogetherEnabled: false,
            practiceType: .soundOff,
            timeBetweenTechniques: 5,
            useTimerForTechniques: true,
            useTimerForExercises: false,
            useTimerForKatas: true,
            useTimerForBlocks: true,
            useTimerForStrikes: true,
            useTimerForKicks: true,
            timeForTechniques: 10,
            timeForExercises: 10,
            timeForKatas: 30,
            timeForBlocks: 5,
            timeForStrikes: 15,
            timeForKicks: 20,
            selectedTechniques: predefinedTechniques,
            selectedExercises: predefinedExercises,
            selectedBlocks: predefinedBlocks,
            selectedStrikes: predefinedStrikes,
            selectedKatas: predefinedKatas,
            selectedKicks: predefinedKicks
        )
    }



    
    func fetchExercises(for session: TrainingSessionEntity) -> [Exercise] {
        guard let selectedExercises = session.selectedExercises?.allObjects as? [ExerciseEntity] else {
            return predefinedExercises // If no selected exercises, return predefined
        }

        // Map selected exercises from Core Data
        let mappedSelectedExercises = selectedExercises.map {
            Exercise(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        }

        // Combine predefined and selected exercises
        var combinedExercises = predefinedExercises

        for selectedExercise in mappedSelectedExercises {
            if let index = combinedExercises.firstIndex(where: { $0.id == selectedExercise.id }) {
                combinedExercises[index].isSelected = true
            } else {
                combinedExercises.append(selectedExercise)
            }
        }

        // Sort combined exercises by order index
        return combinedExercises.sorted(by: { $0.orderIndex < $1.orderIndex })
    }


    func fetchBlocks(for session: TrainingSessionEntity) -> [Block] {
        guard let selectedBlocks = session.selectedBlocks?.allObjects as? [BlockEntity] else {
            return predefinedBlocks // If no selected blocks, return predefined
        }

        // Map selected blocks from Core Data
        let mappedSelectedBlocks = selectedBlocks.map {
            Block(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        }

        // Combine predefined and selected blocks
        var combinedBlocks = predefinedBlocks

        for selectedBlock in mappedSelectedBlocks {
            if let index = combinedBlocks.firstIndex(where: { $0.id == selectedBlock.id }) {
                combinedBlocks[index].isSelected = true
            } else {
                combinedBlocks.append(selectedBlock)
            }
        }

        // Sort combined blocks by order index
        return combinedBlocks.sorted(by: { $0.orderIndex < $1.orderIndex })
    }


    func fetchStrikes(for session: TrainingSessionEntity) -> [Strike] {
        guard let selectedStrikes = session.selectedStrikes?.allObjects as? [StrikeEntity] else {
            return predefinedStrikes // If no selected strikes, return predefined
        }

        // Map selected strikes from Core Data
        let mappedSelectedStrikes = selectedStrikes.map {
            Strike(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected,
                type: $0.type ?? "Unknown",
                preferredStance: $0.preferredStance ?? "None",
                repetitions: Int($0.repetitions),
                timePerMove: Int($0.timePerMove),
                requiresBothSides: $0.requiresBothSides,
                leftCompleted: $0.leftCompleted,
                rightCompleted: $0.rightCompleted
            )
        }

        // Combine predefined and selected strikes
        var combinedStrikes = predefinedStrikes

        for selectedStrike in mappedSelectedStrikes {
            if let index = combinedStrikes.firstIndex(where: { $0.id == selectedStrike.id }) {
                combinedStrikes[index].isSelected = true
            } else {
                combinedStrikes.append(selectedStrike)
            }
        }

        // Sort combined strikes by order index
        return combinedStrikes.sorted(by: { $0.orderIndex < $1.orderIndex })
    }


    func fetchKatas(for session: TrainingSessionEntity) -> [Kata] {
        guard let selectedKatas = session.selectedKatas?.allObjects as? [KataEntity] else {
            return predefinedKatas // If no selected katas, return predefined
        }

        // Map selected katas from Core Data
        let mappedSelectedKatas = selectedKatas.map {
            Kata(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                kataNumber: Int($0.kataNumber),
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        }

        // Combine predefined and selected katas
        var combinedKatas = predefinedKatas

        for selectedKata in mappedSelectedKatas {
            if let index = combinedKatas.firstIndex(where: { $0.id == selectedKata.id }) {
                combinedKatas[index].isSelected = true
            } else {
                combinedKatas.append(selectedKata)
            }
        }

        // Sort combined katas by order index
        return combinedKatas.sorted(by: { $0.orderIndex < $1.orderIndex })
    }


    func fetchKicks(for session: TrainingSessionEntity) -> [Kick] {
        guard let selectedKicks = session.selectedKicks?.allObjects as? [KickEntity] else {
            return predefinedKicks // If no selected kicks, return predefined
        }

        // Map selected kicks from Core Data
        let mappedSelectedKicks = selectedKicks.map {
            Kick(
                id: $0.id ?? UUID(),
                name: $0.name ?? "Unnamed",
                orderIndex: Int($0.orderIndex),
                isSelected: $0.isSelected
            )
        }

        // Combine predefined and selected kicks
        var combinedKicks = predefinedKicks

        for selectedKick in mappedSelectedKicks {
            if let index = combinedKicks.firstIndex(where: { $0.id == selectedKick.id }) {
                // Update predefined kick's selection state
                combinedKicks[index].isSelected = true
            } else {
                // Add any new selected kicks that are not in predefined
                combinedKicks.append(selectedKick)
            }
        }

        // Sort combined kicks by order index
        return combinedKicks.sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    // Helper function to load and sort entities
    private func loadEntities<T: Identifiable & Selectable & Hashable>(
        from coreDataEntities: NSSet?,
        into localArray: inout [T],
        predefinedList: [T]
    ) {
        guard let entities = coreDataEntities as? Set<T> else { return }

        // Sort entities explicitly
        let sortedEntities = entities.sorted { $0.orderIndex < $1.orderIndex }
        for entity in sortedEntities {
            if let matchingItem = predefinedList.first(where: { $0.id == entity.id }) {
                var item = matchingItem
                item.isSelected = true
                item.orderIndex = entity.orderIndex
                localArray.append(item)
            } else {
                print("Could not find a matching predefined item for ID: \(entity.id)")
            }
        }

        // Add any predefined items not already in the local array
        for predefinedItem in predefinedList where !localArray.contains(where: { $0.id == predefinedItem.id }) {
            var item = predefinedItem
            item.isSelected = false
            localArray.append(item)
        }

        // Sort the final list explicitly
        localArray.sort { $0.orderIndex < $1.orderIndex }
    }
    
    func fetchSession(by id: UUID) -> TrainingSessionEntity? {
        let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch session by id: \(error)")
            return nil
        }
    }

    
}

extension DataManager {
    func loadPredefinedTechniques() -> [Technique] {
        return predefinedTechniques
    }
    
    func loadPredefinedExercises() -> [Exercise] {
        return predefinedExercises
    }
    
    func loadPredefinedKatas() -> [Kata] {
        return predefinedKatas
    }
    
    func loadPredefinedBlocks() -> [Block] {
        return predefinedBlocks
    }
    
    func loadPredefinedStrikes() -> [Strike] {
        return predefinedStrikes
    }
    
    func loadPredefinedKicks() -> [Kick] {
        return predefinedKicks
    }
}
