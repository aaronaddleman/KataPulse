//
//  TrainingSession.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 9/20/24.
//

import Foundation

struct TrainingSession {
    var name: String
    var techniques: [Technique]
    var exercises: [Exercise]
    var katas: [Kata]
    var timeBetweenTechniques: Int
    var randomizeTechniques: Bool
    var isFeetTogetherEnabled: Bool
}

let predefinedTrainingSessions: [TrainingSession] = [
    TrainingSession(
        name: "Beginner Session",
        techniques: [
            Technique(name: "Punch", beltLevel: "White", timeToComplete: 5),
            Technique(name: "Kick", beltLevel: "White", timeToComplete: 7)
        ],
        exercises: [
            Exercise(name: "Pushups"),
            Exercise(name: "Squats")
        ],
        katas: [
            Kata(name: "Kata 1", kataNumber: 1)
        ],
        timeBetweenTechniques: 5, // 5 seconds between techniques
        randomizeTechniques: false,
        isFeetTogetherEnabled: true
    ),
    TrainingSession(
        name: "Intermediate Session",
        techniques: [
            Technique(name: "Block", beltLevel: "Orange", timeToComplete: 4),
            Technique(name: "Strike", beltLevel: "Orange", timeToComplete: 6)
        ],
        exercises: [
            Exercise(name: "Lunges"),
            Exercise(name: "Planks")
        ],
        katas: [
            Kata(name: "Kata 2", kataNumber: 2)
        ],
        timeBetweenTechniques: 7,
        randomizeTechniques: true,
        isFeetTogetherEnabled: false
    )
]
