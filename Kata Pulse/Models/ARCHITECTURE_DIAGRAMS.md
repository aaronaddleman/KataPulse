# Motion Detection System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER TRAINING SESSION                        │
│                       (StartTrainingView.swift)                      │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ User reaches Block exercise
                             ▼
                    ┌─────────────────┐
                    │ handleBlockStep │
                    └────────┬────────┘
                             │
                  ┌──────────┴──────────┐
                  │  Is Motion          │
                  │  Validation         │◄────── User Setting
                  │  Enabled?           │        (AppStorage)
                  └──┬──────────────┬───┘
                     │              │
                YES  │              │  NO
                     │              │
                     ▼              ▼
        ┌────────────────────┐   ┌──────────────┐
        │ Motion Validation  │   │   Original   │
        │      Flow          │   │     Flow     │
        └─────────┬──────────┘   └──────────────┘
                  │
                  │
┌─────────────────▼──────────────────────────────────────────────────┐
│                    MOTION VALIDATION SYSTEM                         │
│                  (BlockMotionValidator.swift)                       │
│                                                                     │
│  Responsibilities:                                                  │
│  • Lifecycle management (start/stop)                               │
│  • Coordinate detection and validation                             │
│  • Provide user feedback                                           │
│  • Block progression until correct movement                        │
│                                                                     │
│  State Management:                                                  │
│  @Published var isMonitoring: Bool                                 │
│  @Published var detectionStatus: DetectionStatus                   │
│  @Published var canProceedToNext: Bool ◄─── KEY: Blocks progress  │
│  @Published var motionIntensity: Double                            │
│                                                                     │
└──────────────┬─────────────────────┬──────────────────────────────┘
               │                     │
               │ Sensor Data         │ Validation Request
               ▼                     ▼
┌──────────────────────┐   ┌─────────────────────────┐
│   Apple Watch        │   │  BlockMotionClassifier  │
│   CoreMotion         │   │      (.swift)           │
│                      │   │                         │
│  • Accelerometer     │   │  Pattern Recognition:   │
│  • Gyroscope         │───►  • Inward Block        │
│  • 20Hz updates      │   │  • Outward Block        │
│                      │   │  • Upward Block         │
└──────────────────────┘   │  • Downward Block       │
                           │  • Reverse Hand Block   │
                           │                         │
                           │  Confidence Scoring     │
                           │  (0.0 - 1.0)            │
                           └────────┬────────────────┘
                                    │
                                    │ Classification Result
                                    ▼
                           ┌─────────────────┐
                           │   Validation    │
                           │   Logic         │
                           └────────┬────────┘
                                    │
                ┌───────────────────┼───────────────────┐
                │                   │                   │
                ▼                   ▼                   ▼
         ┌──────────┐        ┌──────────┐      ┌──────────┐
         │ CORRECT  │        │INCORRECT │      │ TIMEOUT  │
         │    ✅    │        │    ❌    │      │    ⏱️    │
         └─────┬────┘        └─────┬────┘      └─────┬────┘
               │                   │                  │
               │                   │                  │
               ▼                   ▼                  ▼
    ┌──────────────────┐  ┌─────────────────┐  ┌──────────────┐
    │ Advance to Next  │  │ Block Progress  │  │   Retry      │
    │   Repetition     │  │ Must Try Again  │  │  Reminder    │
    └──────────────────┘  └─────────────────┘  └──────────────┘
               │
               │ All reps complete?
               ▼
        ┌──────────────┐
        │ Move to Next │
        │   Exercise   │
        └──────────────┘
```

## Data Flow Diagram

```
                    SENSOR DATA COLLECTION
                           (20 Hz)
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Motion Buffer                          │
│  ┌──────┬──────┬──────┬──────┬──────┬─────────┬──────┐    │
│  │Sample│Sample│Sample│Sample│Sample│   ...   │Sample│    │
│  │  1   │  2   │  3   │  4   │  5   │         │  20  │    │
│  └──────┴──────┴──────┴──────┴──────┴─────────┴──────┘    │
│                                                             │
│  Each sample contains:                                      │
│  • Acceleration (X, Y, Z)                                   │
│  • Rotation Rate (X, Y, Z)                                  │
│  • Timestamp                                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
          ┌────────────────────────┐
          │  Calculate Statistics  │
          │                        │
          │  • Average Direction   │
          │  • Primary Rotation    │
          │  • Magnitude          │
          │  • Variance           │
          └───────────┬────────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Pattern Matching     │
          │                       │
          │  Compare against:     │
          │  • Inward signature   │
          │  • Outward signature  │
          │  • Upward signature   │
          │  • Downward signature │
          │  • Reverse signature  │
          └───────────┬───────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Best Match + Score   │
          │                       │
          │  BlockType: Inward    │
          │  Confidence: 0.85     │
          └───────────┬───────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Threshold Check      │
          │                       │
          │  if confidence >= 0.7 │
          │    → Valid detection  │
          │  else                 │
          │    → Keep monitoring  │
          └───────────┬───────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Compare with         │
          │  Expected Block       │
          │                       │
          │  Detected: Inward     │
          │  Expected: Inward     │
          │  → MATCH ✅          │
          └───────────────────────┘
```

## Component Interaction Sequence

```
User               StartTraining        BlockMotion         BlockMotion         CoreMotion
                      View               Validator          Classifier          (Watch)
 │                     │                     │                   │                  │
 │  Starts Block      │                     │                   │                  │
 │  Exercise          │                     │                   │                  │
 │───────────────────►│                     │                   │                  │
 │                    │                     │                   │                  │
 │                    │  startMonitoring()  │                   │                  │
 │                    │────────────────────►│                   │                  │
 │                    │                     │                   │                  │
 │                    │                     │  Start Sensor     │                  │
 │                    │                     │  Updates          │                  │
 │                    │                     │──────────────────────────────────────►│
 │                    │                     │                   │                  │
 │                    │                     │◄─ Motion Data ─────────────────────────│
 │                    │                     │   (20x/second)    │                  │
 │                    │                     │                   │                  │
 │  Performs          │                     │  classifyMotion() │                  │
 │  Inward            │                     │──────────────────►│                  │
 │  Block             │                     │                   │                  │
 │                    │                     │                   │ Analyze Pattern  │
 │                    │                     │                   │ Calculate Score  │
 │                    │                     │                   │                  │
 │                    │                     │ ◄── BlockType ────┤                  │
 │                    │                     │     + Confidence  │                  │
 │                    │                     │                   │                  │
 │                    │                     │ validateMotion()  │                  │
 │                    │                     │──────────────────►│                  │
 │                    │                     │                   │                  │
 │                    │                     │◄─ isCorrect=true ┤                  │
 │                    │                     │                   │                  │
 │                    │◄─ onCorrectMovement─┤                   │                  │
 │                    │   callback          │                   │                  │
 │                    │                     │                   │                  │
 │◄─ Visual Feedback ─┤                     │                   │                  │
 │   "Correct!" ✅    │                     │                   │                  │
 │   Haptic Buzz      │                     │                   │                  │
 │                    │                     │                   │                  │
 │                    │  advanceToNextRep() │                   │                  │
 │                    │────────────────────►│                   │                  │
 │                    │                     │                   │                  │
 │  Next              │                     │  reset()          │                  │
 │  Repetition        │                     │──────────────────►│                  │
 │                    │                     │                   │                  │
```

## State Machine Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    BlockMotionValidator                         │
│                        State Machine                            │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │   WAITING    │◄──── Initial State
                    │      🟡      │
                    └──────┬───────┘
                           │
                           │ Motion > threshold
                           │
                           ▼
                    ┌──────────────┐
                    │  DETECTING   │
                    │      🔵      │◄──────┐
                    └──────┬───────┘       │
                           │               │
          ┌────────────────┼────────────────┼──────────┐
          │                │                │          │
    Unknown or         Correct          Incorrect   Timeout
    Low Confidence     Match            Match       (10s)
          │                │                │          │
          └────────────────┤                │          │
                           ▼                ▼          ▼
                    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
                    │   CORRECT    │ │  INCORRECT   │ │   TIMEOUT    │
                    │      ✅      │ │      ❌      │ │      ⏱️      │
                    └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
                           │                │                 │
                    canProceedToNext   canProceedToNext  canProceedToNext
                         = true             = false          = false
                           │                │                 │
                           │                └─────────┬───────┘
                           │                          │
                           │                     Reset Timer
                           │                     Reset Classifier
                           │                          │
                           │                          │
                           │                          │
                    Advance to Next            Stay on Current
                    Repetition                 (Force Retry)
                           │                          │
                           │                          │
                    All Reps Done?                    │
                           │                          │
                     ┌─────┴─────┐                   │
                    YES          NO                   │
                     │            │                   │
                     ▼            └───────────────────┘
              Next Exercise            Loop Back
```

## UI Component Hierarchy

```
StartTrainingView
│
├─ Body Content (VStack)
│  ├─ Exercise Display
│  ├─ Countdown Timer
│  └─ Progress Indicators
│
└─ .blockMotionValidation() ◄── View Modifier
   │
   └─ BlockMotionValidationOverlay (Conditional)
      │
      ├─ Status Indicator
      │  └─ Circle (color-coded by state)
      │
      ├─ Block Name Display
      │  └─ Text (large, bold)
      │
      ├─ Motion Intensity Bar
      │  ├─ Background (gray)
      │  └─ Foreground (green/animated)
      │
      ├─ Feedback Message
      │  └─ Text (color-coded)
      │
      └─ Attempt Counter
         └─ Text (secondary)
```

## Block Detection Algorithm Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    Motion Sample Arrives                     │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ Add to Buffer   │
                 │ (max 20 samples)│
                 └────────┬────────┘
                          │
                          ▼
                ┌──────────────────┐
                │ Calculate Stats: │
                │                  │
                │ avgX = Σx / n    │
                │ avgY = Σy / n    │
                │ avgZ = Σz / n    │
                │                  │
                │ mag = √(x²+y²+z²)│
                └────────┬─────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ Magnitude Check │
                └────────┬────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
       mag < 1.5                 mag >= 1.5
        (too weak)              (significant)
            │                         │
            ▼                         ▼
      Return UNKNOWN          ┌──────────────┐
                             │Pattern Match: │
                             └───────┬───────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
              ▼                      ▼                      ▼
       ┌────────────┐        ┌────────────┐        ┌────────────┐
       │ Test For   │        │ Test For   │        │ Test For   │
       │   Inward   │        │  Outward   │        │   Upward   │
       │            │        │            │        │            │
       │ ax < -0.5? │        │ ax > 0.5?  │        │ ay > 0.6?  │
       │ ry > 0.3?  │        │ |ry| > 0.2?│        │ rx < -0.3? │
       └────┬───────┘        └────┬───────┘        └────┬───────┘
            │                     │                     │
            └──────────────┬──────┴──────┬──────────────┘
                           │             │
                           ▼             ▼
                    ┌────────────┐  ┌────────────┐
                    │ Test For   │  │ Test For   │
                    │ Downward   │  │  Reverse   │
                    │            │  │            │
                    │ ay < -0.6? │  │ |rz| > 0.5?│
                    └────┬───────┘  └────┬───────┘
                         │               │
                         └───────┬───────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │ Best Match      │
                        │ Found?          │
                        └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                   YES                       NO
                    │                         │
                    ▼                         ▼
          ┌──────────────────┐      Return UNKNOWN
          │ Calculate        │
          │ Confidence Score │
          └────────┬─────────┘
                   │
                   ▼
          ┌──────────────────┐
          │ Confidence >= 0.7?│
          └────────┬─────────┘
                   │
      ┌────────────┴────────────┐
      │                         │
     YES                       NO
      │                         │
      ▼                         ▼
Return BlockType         Return UNKNOWN
with Confidence
```

## Integration Points

```
┌────────────────────────────────────────────────────────────────┐
│                     Your Existing Code                         │
│                   (StartTrainingView.swift)                    │
└────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Add State  │      │    Modify    │      │  Add View    │
│  Variables   │      │  Functions   │      │  Modifier    │
│              │      │              │      │              │
│ @StateObject │      │handleBlock   │      │.blockMotion  │
│  validator   │      │   Step()     │      │ Validation() │
│              │      │              │      │              │
│@AppStorage   │      │Check if      │      │Show overlay  │
│  enabled     │      │  enabled     │      │ when active  │
└──────────────┘      └──────────────┘      └──────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                                ▼
                    ┌───────────────────┐
                    │  Motion Detection │
                    │    Activated!     │
                    └───────────────────┘
```

---

## Key Concepts Summary

### 1. **Separation of Concerns**
- `BlockMotionClassifier`: Pure logic (classification algorithm)
- `BlockMotionValidator`: Business logic (validation & state)
- `BlockTrainingView`: UI presentation
- `BlockTrainingIntegration`: Glue code

### 2. **State Management**
- Published properties for reactive UI
- AppStorage for user preferences
- ObservableObject pattern throughout

### 3. **Progressive Enhancement**
- Works without motion detection (original flow)
- Can be toggled on/off
- No breaking changes to existing code

### 4. **User Feedback Loop**
```
Action → Detection → Validation → Feedback → Next Action
   ↑__________________________________________________|
```

---

This architecture ensures:
- ✅ **Modularity**: Each component has one responsibility
- ✅ **Testability**: Components can be tested independently
- ✅ **Extensibility**: Easy to add new block types or exercises
- ✅ **Maintainability**: Clear separation and documentation
- ✅ **User Control**: Settings allow customization
- ✅ **Robustness**: Graceful degradation if sensors unavailable
