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

    init(id: UUID = UUID(), exerciseName: String, timeTaken: Double = 0.0, type: String) {
        self.id = id
        self.exerciseName = exerciseName
        self.timeTaken = timeTaken
        self.type = type
    }
    
    init(from entity: TrainingSessionHistoryItemsEntity) {
        self.id = entity.id ?? UUID()
        self.exerciseName = entity.exerciseName ?? "Unnamed Item"
        self.timeTaken = entity.timeTaken // Now it's a Double
        self.type = entity.type ?? "Unknown"
    }
}

extension TrainingSessionHistoryItem {
    func toEntity(context: NSManagedObjectContext) -> TrainingSessionHistoryItemsEntity {
        let entity = TrainingSessionHistoryItemsEntity(context: context)
        entity.id = self.id
        entity.exerciseName = self.exerciseName
        entity.timeTaken = self.timeTaken // Now saved as Double
        entity.type = self.type
        // entity.history will be set by TrainingSessionHistory when saving relationships
        return entity
    }
}
