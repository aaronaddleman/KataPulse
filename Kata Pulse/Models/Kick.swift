//
//  Kick.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 10/3/24.
//

import Foundation
import CoreData

struct Kick: Identifiable, Hashable, Comparable, Selectable, BeltLevelItem {
    let id: UUID
    var name: String
    var isSelected: Bool
    var orderIndex: Int
    var beltLevel: BeltLevel

    init(id: UUID = UUID(), name: String, orderIndex: Int = 0, isSelected: Bool = false, beltLevel: BeltLevel = .unknown) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isSelected = isSelected
        self.beltLevel = beltLevel
    }
    
    init(from entity: KickEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
        self.beltLevel = BeltLevel(rawValue: entity.beltLevel ?? "Unknown") ?? .unknown
    }

    static func < (lhs: Kick, rhs: Kick) -> Bool {
        lhs.orderIndex < rhs.orderIndex
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

