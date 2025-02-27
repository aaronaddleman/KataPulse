//
//  TrainingSession.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation

struct TrainingSession {
    var id: UUID
    var name: String
    var techniques: [Technique]
    var practiceType: PracticeType
    var exercises: [Exercise]
    var katas: [Kata]
    var blocks: [Block]
    var strikes: [Strike]
    var kicks: [Kick]
    var timeBetweenTechniques: Int
    var randomizeTechniques: Bool
    var isFeetTogetherEnabled: Bool
}
