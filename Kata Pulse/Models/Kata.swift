//
//  Kata.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Kata: Hashable {
    var name: String
    var kataNumber: Int

    init(name: String, kataNumber: Int) {
        self.name = name
        self.kataNumber = kataNumber
    }

    init(from entity: KataEntity) {
        self.name = entity.name ?? "Unnamed"
        self.kataNumber = Int(entity.kataNumber)
    }
}

extension Kata {
    func toEntity(context: NSManagedObjectContext) -> KataEntity {
        let entity = KataEntity(context: context)
        entity.name = self.name
        entity.kataNumber = Int16(self.kataNumber)
        return entity
    }
}
