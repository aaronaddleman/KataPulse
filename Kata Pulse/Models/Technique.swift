//
//  Technique.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Technique: Identifiable, Hashable {
    let id: UUID // Unique identifier for each technique
    var name: String
    var orderIndex: Int
    var timeToComplete: Int
    var beltLevel: String
    var selected: Bool

    // Updated initializer that accepts 'id'
    init(id: UUID = UUID(), name: String,
         orderIndex: Int = 0, beltLevel: String,
         timeToComplete: Int, selected: Bool = false) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.timeToComplete = timeToComplete
        self.beltLevel = beltLevel
        self.selected = selected
    }

    // Initializer for creating from Core Data entity
    init(from entity: TechniqueEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.timeToComplete = Int(entity.timeToComplete)
        self.beltLevel = entity.beltLevel ?? "Unknown"
        self.selected = entity.isSelected
    }
}

extension Technique {
    func toEntity(context: NSManagedObjectContext) -> TechniqueEntity {
        let entity = TechniqueEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.timeToComplete = Int16(self.timeToComplete)
        entity.beltLevel = self.beltLevel
        entity.isSelected = self.selected
        return entity
    }
}
