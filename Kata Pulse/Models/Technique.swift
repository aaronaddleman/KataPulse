//
//  Technique.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData
import SwiftUI

protocol Selectable {
    var id: UUID { get }
    var name: String { get }
    var isSelected: Bool { get set }
    var orderIndex: Int { get set }
}

struct Technique: Identifiable, Hashable, Selectable, BeltLevelItem {
    let id: UUID
    var name: String
    var orderIndex: Int
    var timeToComplete: Int
    var beltLevel: BeltLevel // ✅ Now uses the enum
    var isSelected: Bool
    var aliases: [String]

    var backgroundColor: Color { beltLevel.backgroundColor }

    init(id: UUID = UUID(), name: String, orderIndex: Int = 0, beltLevel: BeltLevel = .unknown,
         timeToComplete: Int, isSelected: Bool = false, aliases: [String] = []) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.timeToComplete = timeToComplete
        self.beltLevel = beltLevel
        self.isSelected = isSelected
        self.aliases = aliases
    }

    init(from entity: TechniqueEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.timeToComplete = Int(entity.timeToComplete)
        self.beltLevel = BeltLevel(rawValue: entity.beltLevel ?? "Unknown") ?? .unknown
        self.isSelected = entity.isSelected

        if let data = entity.aliases {
            self.aliases = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        } else {
            self.aliases = []
        }
    }

    func toEntity(context: NSManagedObjectContext) -> TechniqueEntity {
        let entity = TechniqueEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.timeToComplete = Int16(self.timeToComplete)
        entity.beltLevel = self.beltLevel.rawValue // ✅ Saves as a string in Core Data
        entity.isSelected = self.isSelected
        entity.aliases = try? JSONEncoder().encode(self.aliases)
        return entity
    }
}


extension Technique: Comparable {
    static func < (lhs: Technique, rhs: Technique) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}
