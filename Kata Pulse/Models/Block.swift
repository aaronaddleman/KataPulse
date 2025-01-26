//
//  Block.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Block: Identifiable, Hashable, Comparable {
    let id: UUID
    var name: String
    var orderIndex: Int
    var isSelected: Bool
    var timestamp: Date
    var repetitions: Int

    init(id: UUID = UUID(), name: String, orderIndex: Int = 0, isSelected: Bool = false, timestamp: Date = Date(), repetitions: Int = 0) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isSelected = isSelected
        self.timestamp = timestamp
        self.repetitions = repetitions
    }
    
    init(from entity: BlockEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
        self.timestamp = entity.timestamp ?? Date()
        self.repetitions = Int(entity.repetitions)
    }
    
    static func < (lhs: Block, rhs: Block) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}

extension Block {
    func toEntity(context: NSManagedObjectContext) -> BlockEntity {
        let entity = BlockEntity(context: context)
        entity.name = self.name
        entity.timestamp = self.timestamp
        entity.repetitions = Int16(self.repetitions)
        return entity
    }
}

