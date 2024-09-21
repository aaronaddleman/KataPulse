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
