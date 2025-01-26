//
//  Kata.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Kata: Identifiable, Hashable, Comparable {
    let id: UUID
    var name: String
    var kataNumber: Int
    var isSelected: Bool
    var orderIndex: Int

    init(id: UUID = UUID(), name: String, kataNumber: Int, orderIndex: Int = 0, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.kataNumber = kataNumber
        self.orderIndex = orderIndex
        self.isSelected = isSelected
    }
    
    init(from entity: KataEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.kataNumber = Int(entity.kataNumber)
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
    }

    static func < (lhs: Kata, rhs: Kata) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}

extension Kata {
    func toEntity(context: NSManagedObjectContext) -> KataEntity {
        let entity = KataEntity(context: context)
        entity.id = self.id // Ensure the id is set
        entity.name = self.name
        entity.kataNumber = Int16(self.kataNumber)
        entity.orderIndex = Int16(self.orderIndex)
        entity.isSelected = self.isSelected
        return entity
    }
}
