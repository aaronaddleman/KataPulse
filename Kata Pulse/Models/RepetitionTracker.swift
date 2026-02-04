//
//  RepetitionTracker.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 7/4/25.
//

import Foundation

struct RepetitionTracker {
    var currentRep: Int = 0
    var totalReps: Int
    var isComplete: Bool { currentRep >= totalReps }
    
    init(totalReps: Int) {
        self.totalReps = totalReps
        self.currentRep = 0
    }
    
    mutating func incrementRep() {
        if currentRep < totalReps {
            currentRep += 1
        }
    }
    
    mutating func reset() {
        currentRep = 0
    }
    
    var progress: Double {
        guard totalReps > 0 else { return 0.0 }
        return Double(currentRep) / Double(totalReps)
    }
    
    var remainingReps: Int {
        max(0, totalReps - currentRep)
    }
}

protocol RepetitionTrackable {
    var repetitionTracker: RepetitionTracker { get set }
    var defaultRepetitions: Int { get }
    
    mutating func startRepetitionTracking()
    mutating func completeRep()
    func isRepetitionComplete() -> Bool
}

extension RepetitionTrackable {
    mutating func startRepetitionTracking() {
        repetitionTracker = RepetitionTracker(totalReps: defaultRepetitions)
    }
    
    mutating func completeRep() {
        repetitionTracker.incrementRep()
    }
    
    func isRepetitionComplete() -> Bool {
        repetitionTracker.isComplete
    }
}