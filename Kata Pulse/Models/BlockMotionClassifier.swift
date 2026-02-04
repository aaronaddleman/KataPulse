//
//  BlockMotionClassifier.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/30/26.
//

import Foundation
import CoreMotion
import os.log

/// Enum representing the different types of blocks that can be detected
enum BlockType: String {
    case inward = "Inward"
    case outward = "Outward"
    case upward = "Upward"
    case downward = "Downward"
    case reverseHand = "Reverse Hand"
    case unknown = "Unknown"
    
    /// Returns the Block model name that matches this block type
    var blockName: String {
        return rawValue
    }
}

/// Result of a motion classification attempt
struct MotionClassificationResult {
    let detectedBlockType: BlockType
    let confidence: Double // 0.0 to 1.0
    let isCorrect: Bool
    let expectedBlockType: BlockType
}

/// Classifies watch motion data into specific blocking techniques
class BlockMotionClassifier: ObservableObject {
    public let logger = Logger(subsystem: "com.katapulse.motiondetection", category: "BlockClassifier")
    
    @Published var currentClassification: BlockType = .unknown
    @Published var classificationConfidence: Double = 0.0
    @Published var isAnalyzing: Bool = false
    
    // Motion data buffers for pattern analysis
    private var accelerationBuffer: [(x: Double, y: Double, z: Double)] = []
    private var rotationBuffer: [(x: Double, y: Double, z: Double)] = []
    private let bufferSize = 20 // Number of samples to analyze
    
    // Detection thresholds
    private let minimumMovementMagnitude: Double = 1.5
    private let confidenceThreshold: Double = 0.7
    
    /// Analyzes motion data and classifies it into a block type
    func classifyMotion(acceleration: CMAcceleration, rotation: CMRotationRate) -> BlockType {
        // Add data to buffers
        accelerationBuffer.append((acceleration.x, acceleration.y, acceleration.z))
        rotationBuffer.append((rotation.x, rotation.y, rotation.z))
        
        // Keep buffer size manageable
        if accelerationBuffer.count > bufferSize {
            accelerationBuffer.removeFirst()
            rotationBuffer.removeFirst()
        }
        
        // Need enough data to analyze
        guard accelerationBuffer.count >= 10 else {
            return .unknown
        }
        
        // Calculate motion characteristics
        let primaryDirection = calculatePrimaryDirection()
        let rotationDirection = calculatePrimaryRotation()
        let magnitude = calculateAverageMagnitude()
        
        // Check if motion is significant enough
        guard magnitude > minimumMovementMagnitude else {
            return .unknown
        }
        
        // Classify based on movement patterns
        let blockType = detectBlockType(
            acceleration: primaryDirection,
            rotation: rotationDirection,
            magnitude: magnitude
        )
        
        // Calculate confidence
        let confidence = calculateConfidence(for: blockType)
        
        DispatchQueue.main.async {
            self.currentClassification = blockType
            self.classificationConfidence = confidence
        }
        
        logger.log("Classified motion: \(blockType.rawValue) with confidence: \(confidence)")
        
        return blockType
    }
    
    /// Detects the block type based on movement patterns
    private func detectBlockType(
        acceleration: (x: Double, y: Double, z: Double),
        rotation: (x: Double, y: Double, z: Double),
        magnitude: Double
    ) -> BlockType {
        let (ax, ay, az) = acceleration
        let (rx, ry, rz) = rotation
        
        // INWARD BLOCK: Movement from outside to centerline (X-axis movement toward body)
        // Watch moves from side toward center with negative X acceleration
        if ax < -0.5 && abs(ay) < 0.3 && ry > 0.3 {
            return .inward
        }
        
        // OUTWARD BLOCK: Movement from centerline outward (positive X acceleration)
        // Watch moves from center toward outside with rotation
        if ax > 0.5 && abs(ay) < 0.3 && abs(ry) > 0.2 {
            return .outward
        }
        
        // UPWARD BLOCK: Upward motion (positive Y acceleration)
        // Strong upward movement with forward rotation
        if ay > 0.6 && abs(ax) < 0.4 && rx < -0.3 {
            return .upward
        }
        
        // DOWNWARD BLOCK: Downward motion (negative Y acceleration)
        // Strong downward movement
        if ay < -0.6 && abs(ax) < 0.4 {
            return .downward
        }
        
        // REVERSE HAND BLOCK: Reverse motion with wrist rotation
        // Characterized by strong Z rotation and mixed X/Y movement
        if abs(rz) > 0.5 && magnitude > 1.8 {
            return .reverseHand
        }
        
        return .unknown
    }
    
    /// Calculates the primary direction of acceleration
    private func calculatePrimaryDirection() -> (x: Double, y: Double, z: Double) {
        guard !accelerationBuffer.isEmpty else {
            return (0, 0, 0)
        }
        
        let avgX = accelerationBuffer.map { $0.x }.reduce(0, +) / Double(accelerationBuffer.count)
        let avgY = accelerationBuffer.map { $0.y }.reduce(0, +) / Double(accelerationBuffer.count)
        let avgZ = accelerationBuffer.map { $0.z }.reduce(0, +) / Double(accelerationBuffer.count)
        
        return (avgX, avgY, avgZ)
    }
    
    /// Calculates the primary rotation direction
    private func calculatePrimaryRotation() -> (x: Double, y: Double, z: Double) {
        guard !rotationBuffer.isEmpty else {
            return (0, 0, 0)
        }
        
        let avgX = rotationBuffer.map { $0.x }.reduce(0, +) / Double(rotationBuffer.count)
        let avgY = rotationBuffer.map { $0.y }.reduce(0, +) / Double(rotationBuffer.count)
        let avgZ = rotationBuffer.map { $0.z }.reduce(0, +) / Double(rotationBuffer.count)
        
        return (avgX, avgY, avgZ)
    }
    
    /// Calculates the average magnitude of motion
    private func calculateAverageMagnitude() -> Double {
        guard !accelerationBuffer.isEmpty else {
            return 0.0
        }
        
        let magnitudes = accelerationBuffer.map { sample in
            sqrt(sample.x * sample.x + sample.y * sample.y + sample.z * sample.z)
        }
        
        return magnitudes.reduce(0, +) / Double(magnitudes.count)
    }
    
    /// Calculates confidence score for the classification
    private func calculateConfidence(for blockType: BlockType) -> Double {
        guard blockType != .unknown else {
            return 0.0
        }
        
        let magnitude = calculateAverageMagnitude()
        let (ax, ay, az) = calculatePrimaryDirection()
        let (rx, ry, rz) = calculatePrimaryRotation()
        
        var confidence: Double = 0.0
        
        switch blockType {
        case .inward:
            confidence = min(1.0, abs(ax) * 1.5 + abs(ry) * 0.5)
        case .outward:
            confidence = min(1.0, abs(ax) * 1.5 + abs(ry) * 0.5)
        case .upward:
            confidence = min(1.0, abs(ay) * 1.3 + abs(rx) * 0.3)
        case .downward:
            confidence = min(1.0, abs(ay) * 1.5)
        case .reverseHand:
            confidence = min(1.0, abs(rz) * 0.8 + magnitude * 0.2)
        case .unknown:
            confidence = 0.0
        }
        
        return confidence
    }
    
    /// Validates if the detected motion matches the expected block
    func validateMotion(
        detectedBlock: BlockType,
        expectedBlock: Block
    ) -> MotionClassificationResult {
        let expectedType = BlockType(rawValue: expectedBlock.name) ?? .unknown
        let isCorrect = detectedBlock == expectedType && classificationConfidence >= confidenceThreshold
        
        return MotionClassificationResult(
            detectedBlockType: detectedBlock,
            confidence: classificationConfidence,
            isCorrect: isCorrect,
            expectedBlockType: expectedType
        )
    }
    
    /// Resets the classifier state
    func reset() {
        accelerationBuffer.removeAll()
        rotationBuffer.removeAll()
        currentClassification = .unknown
        classificationConfidence = 0.0
    }
}
