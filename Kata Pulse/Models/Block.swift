//
//  Block.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Block: Identifiable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

extension Block {
    func toEntity(context: NSManagedObjectContext) -> BlockEntity {
        let entity = BlockEntity(context: context)
        entity.name = self.name
        return entity
    }
}
