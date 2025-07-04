//
//  Block.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Block: Identifiable, Hashable, Comparable, Selectable, BeltLevelItem {
    let id: UUID
    var name: String
    var orderIndex: Int
    var isSelected: Bool
    var timestamp: Date
    var repetitions: Int
    var beltLevel: BeltLevel // ✅ Added belt level support

    init(id: UUID = UUID(), name: String, orderIndex: Int = 0, isSelected: Bool = false,
         timestamp: Date = Date(), repetitions: Int = 0, beltLevel: BeltLevel = .unknown) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isSelected = isSelected
        self.timestamp = timestamp
        self.repetitions = repetitions
        self.beltLevel = beltLevel
    }
    
    /// ✅ Initialize `Block` from Core Data (`BlockEntity`)
    init(from entity: BlockEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
        self.timestamp = entity.timestamp ?? Date()
        self.repetitions = Int(entity.repetitions)
        self.beltLevel = BeltLevel(rawValue: entity.beltLevel ?? "Unknown") ?? .unknown // ✅ Convert from Core Data
    }

    static func < (lhs: Block, rhs: Block) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}

extension Block {
    /// ✅ Convert `Block` back to Core Data (`BlockEntity`)
    func toEntity(context: NSManagedObjectContext) -> BlockEntity {
        let entity = BlockEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.isSelected = self.isSelected
        entity.timestamp = self.timestamp
        entity.repetitions = Int16(self.repetitions)
        entity.beltLevel = self.beltLevel.rawValue  // ✅ Convert to Core Data as a String
        return entity
    }
}
