//
//  CoreDataHelpers.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

// Add your function here
func convertToTrainingSession(from entity: TrainingSessionEntity) -> TrainingSession {
    // Extract techniques from Core Data entities and map them to Technique model
    let techniquesArray: [Technique] = ((entity.selectedTechniques?.allObjects as? [TechniqueEntity])?
          .sorted { $0.orderIndex < $1.orderIndex }
          .map { techniqueEntity in
              Technique(
                  id: techniqueEntity.id ?? UUID(),
                  name: techniqueEntity.name ?? "Unnamed",
                  orderIndex: Int(techniqueEntity.orderIndex),
                  beltLevel: BeltLevel(rawValue: techniqueEntity.beltLevel?.capitalized ?? "Unknown") ?? .unknown,
                  timeToComplete: Int(techniqueEntity.timeToComplete),
                  isSelected: techniqueEntity.isSelected,
                  aliases: (try? JSONDecoder().decode([String].self, from: techniqueEntity.aliases ?? Data())) ?? []
              )
          }) ?? []
    
    // Extract exercises from Core Data entities and map them to Exercise model
    let exercisesArray: [Exercise] = (entity.selectedExercises?.allObjects as? [ExerciseEntity])?.map { exerciseEntity in
        Exercise(
            name: exerciseEntity.name ?? "Unnamed"
        )
    } ?? []

    // Extract katas from Core Data entities and map them to Kata model
    let katasArray: [Kata] = (entity.selectedKatas?.allObjects as? [KataEntity])?.map { kataEntity in
        Kata(
            name: kataEntity.name ?? "Unnamed",
            kataNumber: Int(kataEntity.kataNumber)
        )
    } ?? []
    
    // Extract blocks from Core Data entities and map them to Block model
    let blocksArray: [Block] = (entity.selectedBlocks?.allObjects as? [BlockEntity])?.map { BlockEntity in
        Block(
            name: BlockEntity.name ?? "Unnamed"
        )
    } ?? []
    
    // Extrac strikes from Core Data entities and map them to Strike model
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


    // Extrac strikes from Core Data entities and map them to Strike model
    let kicksArray: [Kick] = (entity.selectedKicks?.allObjects as? [KickEntity])?.map { KickEntity in
        Kick(
            name: KickEntity.name ?? "Unnamed"
        )
    } ?? []
    
    // Ensure the UUID is retrieved from the entity's id or create a new one if not found
    let sessionId = entity.id ?? UUID()
    
    // Convert the practiceType string to the PracticeType enum
    let practiceType = PracticeType(rawValue: entity.practiceType ?? PracticeType.soundOff.rawValue) ?? .soundOff
    
    return TrainingSession(
        id: sessionId,  // Include the id parameter
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


func clearAllData() {
    let context = PersistenceController.shared.container.viewContext
    let entityNames = PersistenceController.shared.container.managedObjectModel.entities.map { $0.name }.compactMap { $0 }

    do {
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(batchDeleteRequest)
        }
        try context.save()
        print("✅ All Core Data entities deleted successfully.")
    } catch {
        print("❌ Failed to delete Core Data entities: \(error.localizedDescription)")
    }
}
