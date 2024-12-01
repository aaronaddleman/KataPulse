//
//  TrainingSessionHistoryItem.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/5/24.
//

import Foundation
import CoreData

struct TrainingSessionHistoryItem: Identifiable, Hashable {
    let id: UUID
    var exerciseName: String
    var timeTaken: Double
    var type: String // e.g., "Kick", "Technique", etc.
    var isKnown: Bool
    
    init(id: UUID = UUID(), exerciseName: String, timeTaken: Double = 0.0, type: String, isKnown: Bool) {
        self.id = id
        self.exerciseName = exerciseName
        self.timeTaken = timeTaken
        self.type = type
        self.isKnown = isKnown
    }
    
    init(from entity: TrainingSessionHistoryItemsEntity) {
        self.id = entity.id ?? UUID()
        self.exerciseName = entity.exerciseName ?? "Unnamed Item"
        self.timeTaken = entity.timeTaken // Now it's a Double
        self.type = entity.type ?? "Unknown"
        self.isKnown = entity.isKnown
        print("Loading from Core Data: \(entity.exerciseName ?? "Unnamed Item"), Known: \(entity.isKnown)")
    }
}

extension TrainingSessionHistoryItem {
    func toEntity(context: NSManagedObjectContext) -> TrainingSessionHistoryItemsEntity {
        let entity = TrainingSessionHistoryItemsEntity(context: context)
        entity.id = self.id
        entity.exerciseName = self.exerciseName
        entity.timeTaken = self.timeTaken // Now saved as Double
        entity.type = self.type
        entity.isKnown = true
        // entity.history will be set by TrainingSessionHistory when saving relationships
        print("Saving to Core Data: \(self.exerciseName), Known: \(self.isKnown)")

        return entity
    }
}
