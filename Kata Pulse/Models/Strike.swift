//
//  Strike.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Strike: Hashable {
    var name: String
    
    init(name: String) {
        self.name = name
    }

    init(from entity: StrikeEntity) {
        self.name = entity.name ?? "Unnamed"
    }
}

extension Strike {
    func toEntity(context: NSManagedObjectContext) -> StrikeEntity {
        let entity = StrikeEntity(context: context)
        entity.name = self.name
        return entity
    }
}
