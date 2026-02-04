//
//  BlockTrainingView.swift
//  Kata Pulse
//
//  Created by Aaron Addleman on 1/30/26.
//

import SwiftUI

/// Interactive view for practicing blocking techniques with motion validation
struct BlockTrainingView: View {
    @StateObject private var motionValidator = BlockMotionValidator()
    @Environment(\.dismiss) private var dismiss
    
    let blocks: [Block]
    @State private var currentBlockIndex: Int = 0
    @State private var completedBlocks: Set<UUID> = []
    @State private var showCompletionAlert: Bool = false
    
    var currentBlock: Block? {
        guard currentBlockIndex < blocks.count else { return nil }
        return blocks[currentBlockIndex]
    }
    
    var progress: Double {
        guard !blocks.isEmpty else { return 0 }
        return Double(completedBlocks.count) / Double(blocks.count)
    }
    
    var body: some View {
        ZStack {
            // Background color based on status
            Color(motionValidator.detectionStatus.color)
                .opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Progress indicator
                progressView
                
                Spacer()
                
                if let block = currentBlock {
                    // Current block information
                    blockInfoView(for: block)
                    
                    // Motion intensity indicator
                    motionIntensityView
                    
                    // Feedback message
                    feedbackView
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtons
                } else {
                    completionView
                }
            }
            .padding()
        }
        .navigationTitle("Block Training")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startCurrentBlock()
        }
        .onDisappear {
            motionValidator.stopMonitoring()
        }
        .alert("Training Complete!", isPresented: $showCompletionAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("You've completed all \(blocks.count) blocks!\n\(completedBlocks.count) successful attempts.")
        }
    }
    
    // MARK: - Subviews
    
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(completedBlocks.count) / \(blocks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.blue)
        }
    }
    
    private func blockInfoView(for block: Block) -> some View {
        VStack(spacing: 12) {
            Text(block.name)
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("BLOCK")
                .font(.caption)
                .foregroundColor(.secondary)
                .tracking(2)
            
            // Belt level indicator
            if block.beltLevel != .unknown {
                Text(block.beltLevel.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(block.beltLevel.backgroundColor)
                    .cornerRadius(8)
            }
            
            // Repetitions remaining
            if block.repetitions > 0 {
                Text("\(block.repetitions) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
    
    private var motionIntensityView: some View {
        VStack(spacing: 8) {
            Text("Motion Intensity")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(motionValidator.isUserMoving ? Color.green : Color.gray)
                    .frame(width: CGFloat(min(motionValidator.motionIntensity * 50, 200)), height: 20)
                    .animation(.easeInOut(duration: 0.1), value: motionValidator.motionIntensity)
            }
            .frame(width: 200)
        }
    }
    
    private var feedbackView: some View {
        VStack(spacing: 8) {
            // Status icon
            statusIcon
            
            // Feedback message
            Text(motionValidator.feedbackMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(statusColor)
            
            // Attempts counter
            if motionValidator.attemptsCount > 0 {
                Text("Attempts: \(motionValidator.attemptsCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var statusIcon: some View {
        Group {
            switch motionValidator.detectionStatus {
            case .waiting:
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
            case .detecting:
                Image(systemName: "waveform")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            case .correct:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            case .incorrect:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            case .timeout:
                Image(systemName: "clock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var statusColor: Color {
        switch motionValidator.detectionStatus {
        case .waiting: return .primary
        case .detecting: return .blue
        case .correct: return .green
        case .incorrect: return .red
        case .timeout: return .orange
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Skip button (for practice mode)
            Button(action: skipCurrentBlock) {
                Label("Skip", systemImage: "forward.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            
            // Next button (only enabled when correct)
            Button(action: moveToNextBlock) {
                Label("Next", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(motionValidator.canProceedToNext ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!motionValidator.canProceedToNext)
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            Text("Training Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You've completed all \(blocks.count) blocks")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Actions
    
    private func startCurrentBlock() {
        guard let block = currentBlock else { return }
        
        // Setup callbacks
        motionValidator.onCorrectMovement = { block in
            completedBlocks.insert(block.id)
        }
        
        motionValidator.onIncorrectMovement = { detected, expected in
            // Could add analytics here
            print("Incorrect: Expected \(expected.name), got \(detected.rawValue)")
        }
        
        motionValidator.onTimeout = {
            // Could add retry logic here
            print("Timeout occurred")
        }
        
        // Start monitoring
        motionValidator.startMonitoring(for: block)
    }
    
    private func moveToNextBlock() {
        guard motionValidator.canProceedToNext else { return }
        
        motionValidator.stopMonitoring()
        currentBlockIndex += 1
        
        if currentBlockIndex < blocks.count {
            startCurrentBlock()
        } else {
            // Training complete
            showCompletionAlert = true
        }
    }
    
    private func skipCurrentBlock() {
        motionValidator.stopMonitoring()
        currentBlockIndex += 1
        
        if currentBlockIndex < blocks.count {
            startCurrentBlock()
        } else {
            showCompletionAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BlockTrainingView(blocks: predefinedBlocks)
    }
}
