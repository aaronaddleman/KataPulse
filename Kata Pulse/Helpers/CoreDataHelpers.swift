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
    let techniquesArray: [Technique] = (entity.selectedTechniques?.allObjects as? [TechniqueEntity])?.map { techniqueEntity in
        Technique(
            name: techniqueEntity.name ?? "Unnamed",
            beltLevel: techniqueEntity.beltLevel ?? "Unknown",
            timeToComplete: Int(techniqueEntity.timeToComplete)
        )
    } ?? []

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
    
    return TrainingSession(
        id: sessionId,  // Include the id parameter
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
