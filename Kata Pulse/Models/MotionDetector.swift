//
//  MotionDetector.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 7/4/25.
//

import Foundation
import CoreMotion

class MotionDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var isDetectingMotion = false
    @Published var motionIntensity: Double = 0.0
    @Published var isMoving = false
    
    private var movementThreshold: Double = 0.15
    private var stillnessThreshold: Double = 0.05
    private var stillnessTimer: Timer?
    private var stillnessDuration: TimeInterval = 2.0
    
    var onRepetitionComplete: (() -> Void)?
    
    init() {
        setupMotionDetection()
    }
    
    private func setupMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
    }
    
    func startDetection() {
        guard !isDetectingMotion else { return }
        
        isDetectingMotion = true
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            let acceleration = data.acceleration
            let magnitude = sqrt(acceleration.x * acceleration.x + 
                               acceleration.y * acceleration.y + 
                               acceleration.z * acceleration.z)
            
            DispatchQueue.main.async {
                self.motionIntensity = magnitude
                self.processMotion(magnitude: magnitude)
            }
        }
    }
    
    func stopDetection() {
        isDetectingMotion = false
        motionManager.stopAccelerometerUpdates()
        stillnessTimer?.invalidate()
        stillnessTimer = nil
        isMoving = false
    }
    
    private func processMotion(magnitude: Double) {
        if magnitude > movementThreshold {
            isMoving = true
            stillnessTimer?.invalidate()
            stillnessTimer = nil
        } else if magnitude < stillnessThreshold && isMoving {
            startStillnessTimer()
        }
    }
    
    private func startStillnessTimer() {
        stillnessTimer?.invalidate()
        stillnessTimer = Timer.scheduledTimer(withTimeInterval: stillnessDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isMoving = false
                self.onRepetitionComplete?()
            }
        }
    }
    
    func configure(
        movementThreshold: Double = 0.15,
        stillnessThreshold: Double = 0.05,
        stillnessDuration: TimeInterval = 2.0
    ) {
        self.movementThreshold = movementThreshold
        self.stillnessThreshold = stillnessThreshold
        self.stillnessDuration = stillnessDuration
    }
    
    deinit {
        stopDetection()
    }
}