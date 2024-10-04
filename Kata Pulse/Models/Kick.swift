//
//  Kick.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/3/24.
//

import Foundation
import CoreData

struct Kick: Identifiable, Hashable {
    let id: UUID
    var name: String
    var isSelected: Bool
    var orderIndex: Int

    init(id: UUID = UUID(), name: String, orderIndex: Int = 0, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isSelected = isSelected
    }
    
    init(from entity: KickEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
    }
}

extension Kick {
    func toEntity(context: NSManagedObjectContext) -> KickEntity {
        let entity = KickEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.isSelected = self.isSelected
        return entity
    }
}

