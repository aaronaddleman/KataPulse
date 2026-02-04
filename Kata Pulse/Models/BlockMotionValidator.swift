//
//  BlockMotionValidator.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/30/26.
//

import Foundation
import CoreMotion
import Combine
import os.log

/// Manages motion detection and validation for blocking exercises
class BlockMotionValidator: ObservableObject {
    public let logger = Logger(subsystem: "com.katapulse.motiondetection", category: "MotionValidator")
    private let motionManager = CMMotionManager()
    private let classifier = BlockMotionClassifier()
    
    @Published var isMonitoring: Bool = false
    @Published var currentExpectedBlock: Block?
    @Published var detectionStatus: DetectionStatus = .waiting
    @Published var feedbackMessage: String = ""
    @Published var canProceedToNext: Bool = false
    @Published var attemptsCount: Int = 0
    
    // Real-time motion feedback
    @Published var motionIntensity: Double = 0.0
    @Published var isUserMoving: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var detectionStartTime: Date?
    private let maxDetectionTime: TimeInterval = 10.0 // Give user 10 seconds per attempt
    
    // Callbacks
    var onCorrectMovement: ((Block) -> Void)?
    var onIncorrectMovement: ((BlockType, Block) -> Void)?
    var onTimeout: (() -> Void)?
    
    enum DetectionStatus {
        case waiting           // Waiting for user to start movement
        case detecting         // Actively detecting movement
        case correct           // Correct movement detected
        case incorrect         // Incorrect movement detected
        case timeout           // User took too long
        
        var color: String {
            switch self {
            case .waiting: return "yellow"
            case .detecting: return "blue"
            case .correct: return "green"
            case .incorrect: return "red"
            case .timeout: return "orange"
            }
        }
    }
    
    init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        motionManager.deviceMotionUpdateInterval = 0.05 // 20Hz update rate
    }
    
    /// Starts monitoring for a specific block movement
    func startMonitoring(for block: Block) {
        logger.log("Starting motion monitoring for block: \(block.name)")
        
        currentExpectedBlock = block
        canProceedToNext = false
        attemptsCount = 0
        detectionStatus = .waiting
        feedbackMessage = "Perform: \(block.name) Block"
        
        startMotionDetection()
    }
    
    /// Stops monitoring and clears state
    func stopMonitoring() {
        logger.log("Stopping motion monitoring")
        
        motionManager.stopDeviceMotionUpdates()
        classifier.reset()
        isMonitoring = false
        detectionStartTime = nil
        detectionStatus = .waiting
        feedbackMessage = ""
        currentExpectedBlock = nil
    }
    
    private func startMotionDetection() {
        guard motionManager.isDeviceMotionAvailable else {
            logger.error("Device motion is not available")
            feedbackMessage = "Motion detection unavailable"
            return
        }
        
        isMonitoring = true
        detectionStartTime = Date()
        detectionStatus = .detecting
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else {
                if let error = error {
                    self?.logger.error("Motion update error: \(error.localizedDescription)")
                }
                return
            }
            
            self.processMotionUpdate(motion)
        }
    }
    
    private func processMotionUpdate(_ motion: CMDeviceMotion) {
        // Calculate motion intensity for visual feedback
        let acceleration = motion.userAcceleration
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        
        DispatchQueue.main.async {
            self.motionIntensity = magnitude
            self.isUserMoving = magnitude > 0.5
        }
        
        // Check for timeout
        if let startTime = detectionStartTime,
           Date().timeIntervalSince(startTime) > maxDetectionTime {
            handleTimeout()
            return
        }
        
        // Only classify if there's significant movement
        guard magnitude > 0.8 else { return }
        
        // Classify the motion
        let detectedBlockType = classifier.classifyMotion(
            acceleration: motion.userAcceleration,
            rotation: motion.rotationRate
        )
        
        // Only validate if we detected a known block type
        guard detectedBlockType != .unknown,
              let expectedBlock = currentExpectedBlock else {
            return
        }
        
        // Validate the detected movement
        let result = classifier.validateMotion(
            detectedBlock: detectedBlockType,
            expectedBlock: expectedBlock
        )
        
        // Only process high-confidence detections
        guard result.confidence > 0.7 else { return }
        
        if result.isCorrect {
            handleCorrectMovement(expectedBlock)
        } else {
            handleIncorrectMovement(detectedBlockType, expectedBlock)
        }
    }
    
    private func handleCorrectMovement(_ block: Block) {
        logger.log("✅ Correct movement detected: \(block.name)")
        
        DispatchQueue.main.async {
            self.detectionStatus = .correct
            self.feedbackMessage = "✅ Correct! \(block.name) Block"
            self.canProceedToNext = true
            
            // Provide haptic feedback
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
            
            // Call success callback
            self.onCorrectMovement?(block)
            
            // Stop monitoring after success
            self.stopMonitoring()
        }
    }
    
    private func handleIncorrectMovement(_ detectedType: BlockType, _ expectedBlock: Block) {
        attemptsCount += 1
        logger.log("❌ Incorrect movement. Expected: \(expectedBlock.name), Detected: \(detectedType.rawValue), Attempts: \(self.attemptsCount)")
        
        DispatchQueue.main.async {
            self.detectionStatus = .incorrect
            self.feedbackMessage = "❌ Incorrect. Expected: \(expectedBlock.name)\nDetected: \(detectedType.rawValue)\nTry again!"
            self.canProceedToNext = false
            
            // Provide haptic feedback
            #if os(watchOS)
            WKInterfaceDevice.current().play(.failure)
            #endif
            
            // Call error callback
            self.onIncorrectMovement?(detectedType, expectedBlock)
            
            // Reset classifier for next attempt
            self.classifier.reset()
            self.detectionStatus = .detecting
            self.detectionStartTime = Date() // Reset timer
        }
    }
    
    private func handleTimeout() {
        logger.log("⏱️ Detection timeout")
        
        DispatchQueue.main.async {
            self.detectionStatus = .timeout
            self.feedbackMessage = "⏱️ Time's up! Try again."
            
            // Provide haptic feedback
            #if os(watchOS)
            WKInterfaceDevice.current().play(.failure)
            #endif
            
            self.onTimeout?()
            
            // Reset for retry
            self.classifier.reset()
            self.detectionStatus = .detecting
            self.detectionStartTime = Date()
        }
    }
    
    /// Manually allows progression (e.g., for skip functionality)
    func allowProgression() {
        logger.log("Manual progression allowed")
        canProceedToNext = true
        stopMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
}
