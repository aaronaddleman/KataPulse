//
//  Block.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Block: Identifiable, Hashable {
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
    
    init(from entity: BlockEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
    }
}

extension Block {
    func toEntity(context: NSManagedObjectContext) -> BlockEntity {
        let entity = BlockEntity(context: context)
        entity.name = self.name
        return entity
    }
}

