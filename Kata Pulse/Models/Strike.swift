//
//  Strike.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Strike: Identifiable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

extension Strike {
    func toEntity(context: NSManagedObjectContext) -> StrikeEntity {
        let entity = StrikeEntity(context: context)
        entity.name = self.name
        return entity
    }
}
