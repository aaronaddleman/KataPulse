//
//  Kata.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Kata: Identifiable, Hashable, Comparable, Selectable, BeltLevelItem {
    let id: UUID
    var name: String
    var kataNumber: Int
    var isSelected: Bool
    var orderIndex: Int
    var beltLevel: BeltLevel  // ✅ Updated to use `BeltLevel` enum

    init(id: UUID = UUID(), name: String, kataNumber: Int, orderIndex: Int = 0, isSelected: Bool = false, beltLevel: BeltLevel = .unknown) {
        self.id = id
        self.name = name
        self.kataNumber = kataNumber
        self.orderIndex = orderIndex
        self.isSelected = isSelected
        self.beltLevel = beltLevel
    }
    
    /// ✅ Initialize `Kata` from Core Data (`KataEntity`)
    init(from entity: KataEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.kataNumber = Int(entity.kataNumber)
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
        self.beltLevel = BeltLevel(rawValue: entity.beltLevel ?? "Unknown") ?? .unknown // ✅ Convert from Core Data
    }

    static func < (lhs: Kata, rhs: Kata) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}

extension Kata {
    /// ✅ Convert `Kata` back to Core Data (`KataEntity`)
    func toEntity(context: NSManagedObjectContext) -> KataEntity {
        let entity = KataEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.kataNumber = Int16(self.kataNumber)
        entity.orderIndex = Int16(self.orderIndex)
        entity.isSelected = self.isSelected
        entity.beltLevel = self.beltLevel.rawValue  // ✅ Convert to Core Data as a String
        return entity
    }
}
