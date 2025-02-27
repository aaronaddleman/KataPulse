//
//  ShuffleHelper.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

struct ShuffleHelper {
    static func shuffleTechniques(_ techniques: inout [Technique]) {
        techniques.shuffle()
        
        // Update the orderIndex to match the new positions
        for (index, technique) in techniques.enumerated() {
            var updatedTechnique = technique
            updatedTechnique.orderIndex = index
            techniques[index] = updatedTechnique
        }
    }
}
