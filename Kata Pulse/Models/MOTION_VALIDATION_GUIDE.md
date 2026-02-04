# Block Motion Validation - Integration Guide

## Overview

This system adds Apple Watch motion detection to validate blocking techniques in real-time. Users must perform the correct blocking movement to proceed to the next exercise.

## Components Created

### 1. **BlockMotionClassifier.swift**
- Analyzes accelerometer and gyroscope data
- Classifies movements into block types: Inward, Outward, Upward, Downward, Reverse Hand
- Calculates confidence scores for detected movements

### 2. **BlockMotionValidator.swift**
- Manages the motion detection lifecycle
- Validates detected movements against expected blocks
- Provides real-time feedback and status updates
- Prevents progression until correct movement is performed

### 3. **BlockTrainingView.swift**
- Standalone view for practicing blocks with motion validation
- Shows progress, motion intensity, and feedback
- Allows skipping for practice mode

### 4. **BlockTrainingIntegration.swift**
- Extension to integrate motion validation into existing StartTrainingView
- View modifier for adding motion validation overlay

### 5. **MotionValidationSettings.swift**
- User settings for enabling/disabling motion validation
- Adjustable strictness levels
- Per-category toggles (blocks, strikes, kicks)

## Integration Steps

### Step 1: Add Motion Validation to StartTrainingView

In `StartTrainingView.swift`, add a state variable for the validator:

```swift
@StateObject private var blockMotionValidator = BlockMotionValidator()
@AppStorage("enableBlockMotionValidation") private var enableBlockMotionValidation = false
```

### Step 2: Update handleBlockStep()

Replace the existing `startBlockFlow` call with the motion-validated version:

```swift
private func handleBlockStep() {
    let blockIndex = currentStep - totalTechniquesExercisesKatasAndKicks()
    
    guard blockIndex < currentBlocks.count else {
        logger.log("Invalid block index: \(blockIndex). Blocks count: \(currentBlocks.count)")
        advanceToNextStep()
        return
    }
    
    let currentBlock = currentBlocks[blockIndex]
    logger.log("Starting block: \(currentBlock.name)")
    
    startTime = Date()
    announce("Get into your stance, prepare for \(currentBlock.name)")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        // Use motion validation if enabled
        if self.enableBlockMotionValidation {
            self.startBlockFlowWithMotionValidation(
                for: currentBlock,
                validator: self.blockMotionValidator
            )
        } else {
            // Use original flow without validation
            self.startBlockFlow(for: currentBlock)
        }
    }
}
```

### Step 3: Add Motion Validation Overlay

Update the `body` view to include the motion validation overlay:

```swift
var body: some View {
    VStack {
        // ... existing content ...
    }
    .blockMotionValidation(
        validator: blockMotionValidator,
        currentBlock: currentBlockIndex < currentBlocks.count ? currentBlocks[currentBlockIndex] : nil
    )
}
```

Where `currentBlockIndex` is:
```swift
private var currentBlockIndex: Int {
    currentStep - totalTechniquesExercisesKatasAndKicks()
}
```

### Step 4: Add Settings Link

In your `SettingsTab` view, add a navigation link:

```swift
NavigationLink(destination: MotionValidationSettings()) {
    Label("Motion Validation", systemImage: "waveform.path")
}
```

### Step 5: Standalone Block Training

To use the standalone block training view:

```swift
NavigationLink(destination: BlockTrainingView(blocks: predefinedBlocks)) {
    Label("Practice Blocks", systemImage: "hand.raised")
}
```

## How It Works

### Motion Detection Flow

1. **User starts block exercise** → `startBlockFlowWithMotionValidation()` is called
2. **Validator starts monitoring** → `BlockMotionValidator.startMonitoring(for: block)`
3. **Motion data collected** → Accelerometer + Gyroscope at 20Hz
4. **Classifier analyzes patterns** → `BlockMotionClassifier.classifyMotion()`
5. **Movement validated** → Compares detected vs expected block type
6. **Feedback provided**:
   - ✅ **Correct**: Advance to next repetition
   - ❌ **Incorrect**: User must retry (with feedback on what was detected)
   - ⏱️ **Timeout**: Reminder + retry

### Block Detection Patterns

Each block type has unique motion signatures:

- **Inward Block**: Negative X acceleration (toward center) + Y rotation
- **Outward Block**: Positive X acceleration (away from center) + rotation
- **Upward Block**: Strong positive Y acceleration + forward rotation
- **Downward Block**: Strong negative Y acceleration
- **Reverse Hand**: High Z rotation + significant magnitude

### Confidence Scoring

The classifier calculates confidence (0.0 to 1.0) based on:
- Acceleration magnitude
- Direction alignment
- Rotation patterns
- Movement consistency

Default threshold: 0.7 (70% confidence required)

## Customization

### Adjust Detection Sensitivity

In `BlockMotionClassifier.swift`:

```swift
private let minimumMovementMagnitude: Double = 1.5  // Lower = more sensitive
private let confidenceThreshold: Double = 0.7       // Lower = less strict
```

### Modify Detection Time

In `BlockMotionValidator.swift`:

```swift
private let maxDetectionTime: TimeInterval = 10.0  // Seconds per attempt
```

### Custom Block Patterns

To add new block types, update the `detectBlockType()` function in `BlockMotionClassifier.swift`:

```swift
// Example: Add a new block type
if ax > 0.8 && ay < -0.3 && rz > 0.4 {
    return .customBlock
}
```

## Testing

### Test Without Apple Watch

For development, you can simulate motion:

```swift
// In BlockMotionValidator
#if DEBUG
func simulateCorrectMovement() {
    if let block = currentExpectedBlock {
        handleCorrectMovement(block)
    }
}
#endif
```

### Test Individual Blocks

Use the standalone `BlockTrainingView` to test each block type:

```swift
BlockTrainingView(blocks: [predefinedBlocks[0]]) // Test just "Inward" block
```

## User Experience

### First Time Setup

1. User enables "Validate Blocks" in Settings
2. During training, motion overlay appears
3. User performs block movement
4. Real-time feedback shows:
   - Motion intensity bar
   - Detection status (waiting/detecting/correct/incorrect)
   - Attempt counter
   - Instructional messages

### Progressive Learning

- **Beginners**: Set strictness to "Lenient" (0.6)
- **Intermediate**: Use "Moderate" (0.7)
- **Advanced**: Use "Strict" (0.85+)

### Accessibility

- Users can disable motion validation entirely
- Skip button available for practice mode
- Voice feedback through existing announcement system
- Visual indicators complement motion detection

## Performance Considerations

- Motion updates run at 20Hz (50ms intervals)
- Classification uses rolling buffer (20 samples)
- Automatic cleanup when view disappears
- Minimal battery impact with efficient algorithms

## Future Enhancements

Potential additions:
- Machine learning model for better accuracy
- Historical movement data analysis
- Personalized calibration
- Video recording of movements
- Form correction suggestions
- Comparison with expert demonstrations

## Troubleshooting

### Motion Not Detected
- Ensure Apple Watch is worn correctly
- Check motion permissions
- Verify watch is charged
- Try adjusting strictness settings

### False Positives
- Increase strictness setting
- Ensure proper stance before movement
- Perform movements deliberately
- Allow watch to settle between reps

### Performance Issues
- Reduce buffer size in classifier
- Increase update interval
- Disable other motion features during validation

## API Reference

### BlockMotionValidator

```swift
class BlockMotionValidator: ObservableObject {
    // Start monitoring for a specific block
    func startMonitoring(for block: Block)
    
    // Stop monitoring and cleanup
    func stopMonitoring()
    
    // Manually allow progression
    func allowProgression()
    
    // Callbacks
    var onCorrectMovement: ((Block) -> Void)?
    var onIncorrectMovement: ((BlockType, Block) -> Void)?
    var onTimeout: (() -> Void)?
}
```

### BlockMotionClassifier

```swift
class BlockMotionClassifier: ObservableObject {
    // Classify motion data into block type
    func classifyMotion(acceleration: CMAcceleration, rotation: CMRotationRate) -> BlockType
    
    // Validate detected motion against expected
    func validateMotion(detectedBlock: BlockType, expectedBlock: Block) -> MotionClassificationResult
    
    // Reset classifier state
    func reset()
}
```

---

**Created by**: Aaron Addleman
**Date**: January 30, 2026
**Version**: 1.0
