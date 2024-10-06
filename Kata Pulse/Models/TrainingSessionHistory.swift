//
//  TrainingSessionHistory.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/5/24.
//

import Foundation
import CoreData

struct TrainingSessionHistory: Identifiable, Hashable {
    let id: UUID
    var sessionName: String
    var timestamp: Date
    var items: [TrainingSessionHistoryItem]

    init(id: UUID = UUID(), sessionName: String, timestamp: Date = Date(), items: [TrainingSessionHistoryItem] = []) {
        self.id = id
        self.sessionName = sessionName
        self.timestamp = timestamp
        self.items = items
    }
    
    init(from entity: TrainingSessionHistoryEntity) {
        self.id = entity.id ?? UUID()
        self.sessionName = entity.sessionName ?? "Unnamed Session"
        self.timestamp = entity.timestamp ?? Date()
        
        // Convert related items from Core Data entities to struct instances
        if let itemEntities = entity.items as? Set<TrainingSessionHistoryItemsEntity> {
            self.items = itemEntities.map { TrainingSessionHistoryItem(from: $0) }
        } else {
            self.items = []
        }
    }
}

extension TrainingSessionHistory {
    func toEntity(context: NSManagedObjectContext) -> TrainingSessionHistoryEntity {
        let entity = TrainingSessionHistoryEntity(context: context)
        entity.id = self.id
        entity.sessionName = self.sessionName
        entity.timestamp = self.timestamp
        
        // Convert items to entities and set relationship
        let itemEntities = self.items.map { item -> TrainingSessionHistoryItemsEntity in
            let itemEntity = item.toEntity(context: context)
            itemEntity.history = entity // Set the reverse relationship
            return itemEntity
        }
        entity.items = NSSet(array: itemEntities)
        
        return entity
    }
}
