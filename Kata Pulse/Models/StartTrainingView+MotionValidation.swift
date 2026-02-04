//
//  StartTrainingView+MotionValidation.swift
//  Kata Pulse
//
//  Integration code for motion validation
//  Copy this code INTO your StartTrainingView.swift file
//

/*
 
 STEP 1: Add these state variables to StartTrainingView (near the top with other @State variables)
 ================================================================================================
 
 @StateObject private var blockMotionValidator = BlockMotionValidator()
 @AppStorage("enableBlockMotionValidation") private var enableBlockMotionValidation = false
 
 
 STEP 2: Add this function to StartTrainingView (add it near your other helper functions)
 ================================================================================================
 
 /// Enhanced block flow with motion validation
 private func startBlockFlowWithMotionValidation(for block: Block, validator: BlockMotionValidator) {
     // Initialize repetition tracker if not already set
     if currentBlockTracker == nil {
         currentBlockTracker = RepetitionTracker(
             totalReps: block.repetitions > 0 ? block.repetitions : block.defaultRepetitions
         )
     }
     
     guard let tracker = currentBlockTracker, !tracker.isComplete else {
         logger.log("Completed all repetitions for \(block.name). Advancing to next block.")
         currentBlockTracker = nil // Reset for the next block
         validator.stopMonitoring()
         advanceToNextStep()
         return
     }
     
     // Announce the current repetition
     let repNumber = tracker.currentRep + 1
     announce("Repetition \(repNumber). Perform \(block.name) block.")
     logger.log("Starting repetition \(repNumber) for block: \(block.name)")
     
     // Start motion monitoring for this block
     validator.startMonitoring(for: block)
     
     // Setup validator callbacks (capturing values, not self since we're in a struct)
     validator.onCorrectMovement = { [validator] validatedBlock in
         // Increment the repetition counter
         self.currentBlockTracker?.incrementRep()
         
         // Provide positive feedback
         self.announce("Correct! Good form on \(validatedBlock.name).")
         
         // Wait a moment before next rep
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
             self.startBlockFlowWithMotionValidation(for: block, validator: validator)
         }
     }
     
     validator.onIncorrectMovement = { detected, expected in
         // Provide corrective feedback
         self.announce("Incorrect. That was a \(detected.rawValue) block. Try again with a \(expected.name) block.")
         
         // Don't increment counter - user must retry
         // Motion validator will automatically reset for next attempt
     }
     
     validator.onTimeout = {
         // Remind user what to do
         self.announce("Time's up. Remember, perform a \(block.name) block.")
         
         // Validator will auto-reset for retry
     }
 }
 
 
 STEP 3: Update your handleBlockStep() function
 ================================================================================================
 
 Find your existing handleBlockStep() function and modify it like this:
 
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
         // ✨ ADD THIS CONDITIONAL:
         if self.enableBlockMotionValidation {
             self.startBlockFlowWithMotionValidation(for: currentBlock, validator: self.blockMotionValidator)
         } else {
             self.startBlockFlow(for: currentBlock) // Original behavior
         }
     }
 }
 
 
 STEP 4: Add the view modifier to your body (OPTIONAL - for visual overlay)
 ================================================================================================
 
 In your StartTrainingView body, wrap your content with the motion validation overlay:
 
 var body: some View {
     VStack {
         // ... your existing content ...
     }
     .blockMotionValidation(
         validator: blockMotionValidator,
         currentBlock: getCurrentBlockIfInBlockStep()
     )
 }
 
 // Helper function to get current block
 private func getCurrentBlockIfInBlockStep() -> Block? {
     let blockStart = totalTechniquesExercisesKatasAndKicks()
     let blockEnd = totalTechniquesExercisesKatasKicksAndBlocks()
     
     guard currentStep >= blockStart && currentStep < blockEnd else {
         return nil
     }
     
     let blockIndex = currentStep - blockStart
     guard blockIndex < currentBlocks.count else {
         return nil
     }
     
     return currentBlocks[blockIndex]
 }
 
*/
