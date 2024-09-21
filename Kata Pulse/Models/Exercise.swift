//
//  Exercise.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Exercise: Hashable {
    var name: String

    init(name: String) {
        self.name = name
    }

    init(from entity: ExerciseEntity) {
        self.name = entity.name ?? "Unnamed"
    }
}

extension Exercise {
    func toEntity(context: NSManagedObjectContext) -> ExerciseEntity {
        let entity = ExerciseEntity(context: context)
        entity.name = self.name
        return entity
    }
}
