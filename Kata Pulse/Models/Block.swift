//
//  Block.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Block: Hashable {
    var name: String
    
    init(name: String) {
        self.name = name
    }

    init(from entity: BlockEntity) {
        self.name = entity.name ?? "Unnamed"
    }
}

extension Block {
    func toEntity(context: NSManagedObjectContext) -> BlockEntity {
        let entity = BlockEntity(context: context)
        entity.name = self.name
        return entity
    }
}
