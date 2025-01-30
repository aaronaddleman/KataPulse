//
//  Strike.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Strike: Identifiable, Hashable, Comparable {
    let id: UUID
    var name: String
    var orderIndex: Int
    var isSelected: Bool
    var type: String
    var preferredStance: String
    var repetitions: Int
    var timePerMove: Int
    var requiresBothSides: Bool
    var leftCompleted: Bool // Tracks left side completion
    var rightCompleted: Bool // Tracks right side completion

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        name: String,
        orderIndex: Int = 0,
        isSelected: Bool = false,
        type: String,
        preferredStance: String,
        repetitions: Int,
        timePerMove: Int,
        requiresBothSides: Bool,
        leftCompleted: Bool = false,
        rightCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.isSelected = isSelected
        self.type = type
        self.preferredStance = preferredStance
        self.repetitions = repetitions
        self.timePerMove = timePerMove
        self.requiresBothSides = requiresBothSides
        self.leftCompleted = leftCompleted
        self.rightCompleted = rightCompleted
    }

    // Initialize from StrikeEntity (Core Data)
    init(from entity: StrikeEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.isSelected = entity.isSelected
        self.type = entity.type ?? "Unknown"
        self.preferredStance = entity.preferredStance ?? "None"
        self.repetitions = Int(entity.repetitions)
        self.timePerMove = Int(entity.timePerMove)
        self.requiresBothSides = entity.requiresBothSides
        self.leftCompleted = entity.leftCompleted
        self.rightCompleted = entity.rightCompleted
    }
    
    static func < (lhs: Strike, rhs: Strike) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}

// MARK: - Core Data Conversion

extension Strike {
    func toEntity(context: NSManagedObjectContext) -> StrikeEntity {
        let entity = StrikeEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.isSelected = self.isSelected
        entity.type = self.type
        entity.preferredStance = self.preferredStance
        entity.repetitions = Int16(self.repetitions)
        entity.timePerMove = Int16(self.timePerMove)
        entity.requiresBothSides = self.requiresBothSides
        entity.leftCompleted = self.leftCompleted
        entity.rightCompleted = self.rightCompleted
        return entity
    }
}
