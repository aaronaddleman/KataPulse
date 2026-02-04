//
//  BlockTrainingIntegration.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/30/26.
//

import SwiftUI

// Note: This file provides integration helpers for motion validation.
// To integrate into StartTrainingView, you'll need to add the functionality
// directly to that view since extensions can't access private properties
// and SwiftUI views are structs (can't use weak self).
//
// See MOTION_VALIDATION_GUIDE.md for integration instructions.

/// View modifier to add motion validation UI overlay
struct BlockMotionValidationOverlay: ViewModifier {
    @ObservedObject var validator: BlockMotionValidator
    let currentBlock: Block?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if validator.isMonitoring, let block = currentBlock {
                VStack {
                    Spacer()
                    
                    // Motion validation feedback card
                    VStack(spacing: 12) {
                        // Status indicator
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 12, height: 12)
                            
                            Text("Motion Detection Active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Current block name
                        Text(block.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Motion intensity bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(validator.isUserMoving ? Color.green : Color.gray)
                                .frame(
                                    width: CGFloat(min(validator.motionIntensity * 100, 300)),
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.1), value: validator.motionIntensity)
                        }
                        .frame(maxWidth: 300)
                        
                        // Feedback message
                        Text(validator.feedbackMessage)
                            .font(.headline)
                            .foregroundColor(feedbackColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Attempts counter
                        if validator.attemptsCount > 0 {
                            Text("Attempts: \(validator.attemptsCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                    .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: validator.isMonitoring)
    }
    
    private var statusColor: Color {
        switch validator.detectionStatus {
        case .waiting: return .yellow
        case .detecting: return .blue
        case .correct: return .green
        case .incorrect: return .red
        case .timeout: return .orange
        }
    }
    
    private var feedbackColor: Color {
        switch validator.detectionStatus {
        case .correct: return .green
        case .incorrect: return .red
        case .timeout: return .orange
        default: return .primary
        }
    }
}

extension View {
    /// Adds motion validation overlay to a view
    func blockMotionValidation(
        validator: BlockMotionValidator,
        currentBlock: Block?
    ) -> some View {
        modifier(BlockMotionValidationOverlay(validator: validator, currentBlock: currentBlock))
    }
}
