//
//  Strike.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Strike: Identifiable, Hashable {
    let id: UUID
    var name: String
    var orderIndex: Int
    var isSelected: Bool

    init(id: UUID = UUID(), name: String, orderIndex: Int = 0, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isSelected = isSelected
    }
    
    init(from entity: ExerciseEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
    }
}

extension Strike {
    func toEntity(context: NSManagedObjectContext) -> StrikeEntity {
        let entity = StrikeEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.isSelected = self.isSelected
        return entity
    }
}
