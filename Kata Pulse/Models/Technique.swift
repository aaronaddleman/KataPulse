//
//  Technique.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData
import SwiftUI

struct Technique: Identifiable, Hashable {
    let id: UUID // Unique identifier for each technique
    var name: String
    var orderIndex: Int
    var timeToComplete: Int
    var beltLevel: String
    var isSelected: Bool // Renamed to `isSelected`

    var backgroundColor: Color {
        switch beltLevel {
        case "White":
            return Color.clear
        case "Yellow":
            return Color.yellow.opacity(0.3) // Add slight opacity for better visibility
        case "Orange":
            return Color.orange.opacity(0.3)
        case "Green":
            return Color.green.opacity(0.3)
        case "Blue":
            return Color.blue.opacity(0.3)
        case "Brown":
            return Color.brown.opacity(0.3)
        case "Black":
            return Color.black.opacity(0.7) // Darker for black belt
        default:
            return Color.gray.opacity(0.3) // Default for unrecognized levels
        }
    }
    
    // Updated initializer that accepts 'id'
    init(id: UUID = UUID(), name: String,
         orderIndex: Int = 0, beltLevel: String,
         timeToComplete: Int, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.timeToComplete = timeToComplete
        self.beltLevel = beltLevel
        self.isSelected = isSelected // Renamed to `isSelected`
    }

    // Initializer for creating from Core Data entity
    init(from entity: TechniqueEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed"
        self.orderIndex = Int(entity.orderIndex)
        self.timeToComplete = Int(entity.timeToComplete)
        self.beltLevel = entity.beltLevel ?? "Unknown"
        self.isSelected = entity.isSelected // Renamed to `isSelected`
    }
}

extension Technique {
    func toEntity(context: NSManagedObjectContext) -> TechniqueEntity {
        let entity = TechniqueEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.orderIndex = Int16(self.orderIndex)
        entity.timeToComplete = Int16(self.timeToComplete)
        entity.beltLevel = self.beltLevel
        entity.isSelected = self.isSelected // Renamed to `isSelected`
        return entity
    }
}
