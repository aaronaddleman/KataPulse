//
//  Exercise.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Exercise: Hashable, Comparable, Identifiable, Selectable, BeltLevelItem {
    let id: UUID
    var name: String
    var orderIndex: Int
    var isSelected: Bool
    var beltLevel: BeltLevel
        
    init(id: UUID = UUID(), name: String,
         orderIndex: Int = 0, isSelected: Bool = false, beltLevel: BeltLevel = .unknown) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isSelected = isSelected
        self.beltLevel = beltLevel
    }
    
    init(from entity: ExerciseEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
        self.beltLevel = BeltLevel(rawValue: entity.beltLevel ?? "Unknown") ?? .unknown // ✅ Convert from Core Data
    }
    
    static func < (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}

extension Exercise {
    func toEntity(context: NSManagedObjectContext) -> ExerciseEntity {
        let entity = ExerciseEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.isSelected = self.isSelected
        return entity
    }
}
