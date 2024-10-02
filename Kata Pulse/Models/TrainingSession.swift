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
    var exercises: [Exercise]
    var katas: [Kata]
    var blocks: [Block]
    var strikes: [Strike]
    var timeBetweenTechniques: Int
    var randomizeTechniques: Bool
    var isFeetTogetherEnabled: Bool
}

//let predefinedTrainingSessions: [TrainingSession] = [
//    TrainingSession(
//        name: "Beginner Session",
//        techniques: [
//            Technique(name: "Punch", beltLevel: "White", timeToComplete: 5),
//            Technique(name: "Kick", beltLevel: "White", timeToComplete: 7)
//        ],
//        exercises: [
//            Exercise(name: "Pushups"),
//            Exercise(name: "Squats")
//        ],
//        katas: [
//            Kata(name: "Kata 1", kataNumber: 1)
//        ],
//        blocks: [
//            Block(name: "Innward"),
//            Block(name: "Outward"),
//            Block(name: "Upward"),
//            Block(name: "Downward"),
//            Block(name: "Reverse Hand")
//        ],
//        strikes: [
//            Strike(name: "Chop to the throt"),
//            Strike(name: "Side fist")
//        ],
//        timeBetweenTechniques: 5, // 5 seconds between techniques
//        randomizeTechniques: false,
//        isFeetTogetherEnabled: true
//    ),
//    TrainingSession(
//        name: "Intermediate Session",
//        techniques: [
//            Technique(name: "Block", beltLevel: "Orange", timeToComplete: 4),
//            Technique(name: "Strike", beltLevel: "Orange", timeToComplete: 6)
//        ],
//        exercises: [
//            Exercise(name: "Lunges"),
//            Exercise(name: "Planks")
//        ],
//        katas: [
//            Kata(name: "Kata 2", kataNumber: 2)
//        ],
//        blocks: [
//            Block(name: "Innward"),
//            Block(name: "Outward"),
//            Block(name: "Upward"),
//            Block(name: "Downward"),
//            Block(name: "Reverse Hand")
//        ],
//        strikes: [
//            Strike(name: "Chop to the throt"),
//            Strike(name: "Side fist")
//        ],
//        timeBetweenTechniques: 7,
//        randomizeTechniques: true,
//        isFeetTogetherEnabled: false
//    )
//]
