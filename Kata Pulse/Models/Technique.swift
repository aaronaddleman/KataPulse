//
//  Technique.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Technique: Hashable {
    var name: String
    var beltLevel: String
    var timeToComplete: Int

    init(name: String, beltLevel: String, timeToComplete: Int) {
        self.name = name
        self.beltLevel = beltLevel
        self.timeToComplete = timeToComplete
    }

    init(from entity: TechniqueEntity) {
        self.name = entity.name ?? "Unnamed"
        self.beltLevel = entity.beltLevel ?? "Unknown"
        self.timeToComplete = Int(entity.timeToComplete)
    }
    
}

extension Technique {
    func toEntity(context: NSManagedObjectContext) -> TechniqueEntity {
        let entity = TechniqueEntity(context: context)
        entity.name = self.name
        entity.beltLevel = self.beltLevel
        entity.timeToComplete = Int16(self.timeToComplete)
        return entity
    }
}
