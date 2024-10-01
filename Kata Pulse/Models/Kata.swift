//
//  Kata.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation
import CoreData

struct Kata: Identifiable, Hashable {
    let id: UUID
    var name: String
    var kataNumber: Int

    init(id: UUID = UUID(), name: String, kataNumber: Int) {
        self.id = id
        self.name = name
        self.kataNumber = kataNumber
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
