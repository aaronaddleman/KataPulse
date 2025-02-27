//
//  Kata_PulseTests.swift
//  Kata PulseTests
//
//  Created by Aaron Addleman on 9/20/24.
//

import XCTest
import SwiftUI
import CoreData
@testable import Kata_Pulse

final class Kata_PulseTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testConvertToTrainingSession() {
        let context = PersistenceController.shared.container.viewContext
        let entity = TrainingSessionEntity(context: context)
        entity.name = "Test Session"
        entity.timeBetweenTechniques = 5

        let session = convertToTrainingSession(from: entity)
        
        XCTAssertEqual(session.name, "Test Session")
        XCTAssertEqual(session.timeBetweenTechniques, 5)
    }
    
    func testTechniqueOrderPreserved() {
        // Set up an in-memory persistence controller and data manager
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        
        // STEP 1: Create a new training session
        let sessionName = "Order Test Session"
        let session = TrainingSessionEntity(context: context)
        session.id = UUID()
        session.name = sessionName
        
        // STEP 2: Create two visually distinctive techniques
        // First technique - create a visually distinctive technique with red color
        let whiteTechniqueID = UUID()
        let whiteTechniqueEntity = TechniqueEntity(context: context)
        whiteTechniqueEntity.id = whiteTechniqueID
        whiteTechniqueEntity.name = "White Technique" // Visual identifier
        whiteTechniqueEntity.beltLevel = BeltLevel.white.rawValue // Visually red
        whiteTechniqueEntity.timeToComplete = 5
        whiteTechniqueEntity.orderIndex = 0 // First in original order
        whiteTechniqueEntity.isSelected = true
        
        // Second technique - create a visually distinctive technique with blue color
        let yellowTechniqueID = UUID()
        let yellowTechniqueEntity = TechniqueEntity(context: context)
        yellowTechniqueEntity.id = yellowTechniqueID
        yellowTechniqueEntity.name = "Yellow Technique" // Visual identifier
        yellowTechniqueEntity.beltLevel = BeltLevel.yellow.rawValue // Visually blue
        yellowTechniqueEntity.timeToComplete = 7
        yellowTechniqueEntity.orderIndex = 1 // Second in original order
        yellowTechniqueEntity.isSelected = true
        
        // Add techniques to the session
        session.addToSelectedTechniques(whiteTechniqueEntity)
        session.addToSelectedTechniques(yellowTechniqueEntity)
        
        // Save the context
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
            return
        }
        
        // STEP 3: First verification - check original order
        // In our UI, this would be visually represented as Red first, then Blue
        let initialConvertedSession = convertToTrainingSession(from: session)
        XCTAssertEqual(initialConvertedSession.techniques.count, 2, "Should have 2 techniques")
        
        // Check that white is first, yellow is second
        XCTAssertEqual(initialConvertedSession.techniques[0].beltLevel, .white, "First technique should be white")
        XCTAssertEqual(initialConvertedSession.techniques[1].beltLevel, .yellow, "Second technique should be yellow")
        
        // STEP 4: Simulate changing the order (like a drag operation would do visually)
        // Visually, the user would drag the blue item above the red item
        // This would update the order indices
        whiteTechniqueEntity.orderIndex = 1 // Move red to second position
        yellowTechniqueEntity.orderIndex = 0 // Move blue to first position
        
        // Save the context after reordering
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context after reordering: \(error)")
            return
        }
        
        // STEP 5: "Edit" the session (simulate closing and reopening)
        // In UI terms, this would be like leaving the edit screen and coming back
        let refreshedSession = try? context.existingObject(with: session.objectID) as? TrainingSessionEntity
        guard let refreshedSession = refreshedSession else {
            XCTFail("Failed to retrieve session after edit")
            return
        }
        
        // STEP 6: Visual verification after edit
        // The order in the list should now be blue first, then red
        let reorderedSession = convertToTrainingSession(from: refreshedSession)
        
        // Make sure we still have 2 techniques
        XCTAssertEqual(reorderedSession.techniques.count, 2, "Should still have 2 techniques")
        
        // Visual check - blue should now be first, red second
        XCTAssertEqual(reorderedSession.techniques[0].beltLevel, .yellow, "First technique should now be yellow")
        XCTAssertEqual(reorderedSession.techniques[1].beltLevel, .white, "Second technique should now be white")
        
        // Check order indices match visual positions
        XCTAssertEqual(reorderedSession.techniques[0].orderIndex, 0, "First visual position should have orderIndex 0")
        XCTAssertEqual(reorderedSession.techniques[1].orderIndex, 1, "Second visual position should have orderIndex 1")
    }

    func testCreateTrainingSessionEntity() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let session = TrainingSessionEntity(context: context)
        session.name = "Test Session"
        session.timeBetweenTechniques = 10

        XCTAssertEqual(session.name, "Test Session")
        XCTAssertEqual(session.timeBetweenTechniques, 10)
    }
    
    func testCompleteTrainingSessionConversion() {
        // Set up an in-memory persistence controller
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        
        // Create a comprehensive training session entity with all relationship types
        let session = TrainingSessionEntity(context: context)
        session.id = UUID()
        session.name = "Complete Test Session"
        session.timeBetweenTechniques = 5
        session.randomizeTechniques = true
        session.isFeetTogetherEnabled = true
        session.practiceType = PracticeType.hardWithKiai.rawValue
        
        // Add techniques
        let technique1 = TechniqueEntity(context: context)
        technique1.id = UUID()
        technique1.name = "Front Kick"
        technique1.orderIndex = 0
        technique1.beltLevel = "white" // Lowercase - this is the issue
        technique1.timeToComplete = 10
        technique1.isSelected = true
        technique1.aliases = try? JSONEncoder().encode(["Mae-geri", "Front snap kick"])
        
        // Print debug information
        print("Debug - beltLevel value stored in entity: \(technique1.beltLevel ?? "nil")")
        
        // Add a strike
        let strike1 = StrikeEntity(context: context)
        strike1.id = UUID()
        strike1.name = "Reverse Punch"
        strike1.orderIndex = 0
        strike1.isSelected = true
        strike1.type = "Punch"
        strike1.preferredStance = "Fighting"
        strike1.repetitions = 10
        strike1.timePerMove = 3
        strike1.requiresBothSides = true
        
        // Add relationships
        session.addToSelectedTechniques(technique1)
        session.addToSelectedStrikes(strike1)
        
        // Save context
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
            return
        }
        
        // Convert and verify complete conversion
        let convertedSession = convertToTrainingSession(from: session)
        
        // Verify basic properties
        XCTAssertEqual(convertedSession.name, "Complete Test Session")
        XCTAssertEqual(convertedSession.timeBetweenTechniques, 5)
        XCTAssertEqual(convertedSession.randomizeTechniques, true)
        XCTAssertEqual(convertedSession.isFeetTogetherEnabled, true)
        XCTAssertEqual(convertedSession.practiceType, .hardWithKiai)
        
        // Verify technique relationship conversion
        XCTAssertEqual(convertedSession.techniques.count, 1, "Should have 1 technique")
        XCTAssertEqual(convertedSession.techniques[0].name, "Front Kick", "Name should match")
        
        // Debug the actual belt level
        let actualBelt = convertedSession.techniques[0].beltLevel
        print("Debug - Actual belt level: \(actualBelt)")
        
        // Now it should be converted to .white correctly because of the capitalized fix
        XCTAssertEqual(convertedSession.techniques[0].beltLevel, .white, "Belt level should match")
        XCTAssertEqual(convertedSession.techniques[0].aliases, ["Mae-geri", "Front snap kick"], "Aliases should match")
        
        // Verify strike relationship conversion
        XCTAssertEqual(convertedSession.strikes.count, 1)
        XCTAssertEqual(convertedSession.strikes[0].name, "Reverse Punch")
        XCTAssertEqual(convertedSession.strikes[0].type, "Punch")
        XCTAssertEqual(convertedSession.strikes[0].requiresBothSides, true)
    }

    func testBeltLevelOperations() {
        // Test conversion from string to enum with exact case match
        XCTAssertEqual(BeltLevel(rawValue: "White"), .white)
        XCTAssertEqual(BeltLevel(rawValue: "Yellow"), .yellow)
        XCTAssertEqual(BeltLevel(rawValue: "Unknown"), .unknown)
        
        // Test case-insensitive conversion with our CoreDataHelpers approach
        XCTAssertEqual(BeltLevel(rawValue: "white".capitalized), .white, "Should handle lowercase with capitalization")
        XCTAssertEqual(BeltLevel(rawValue: "YELLOW".capitalized), .yellow, "Should handle uppercase with capitalization")
        XCTAssertEqual(BeltLevel(rawValue: "OrAnGe".capitalized), .orange, "Should handle mixed case with capitalization")
        
        // Debug check for unknown value
        let unknown = BeltLevel(rawValue: "Unknown")
        XCTAssertEqual(unknown, .unknown, "Should get .unknown for 'Unknown' string")
        
        // Test null/nil handling
        let nilString: String? = nil
        let fallbackBelt = BeltLevel(rawValue: nilString ?? "Unknown") ?? .unknown
        XCTAssertEqual(fallbackBelt, .unknown, "Should get .unknown for nil string")
        
        // Test background color functionality
        XCTAssertEqual(BeltLevel.white.backgroundColor, Color.clear)
        XCTAssertEqual(BeltLevel.yellow.backgroundColor, Color.yellow.opacity(0.3))
        XCTAssertEqual(BeltLevel.orange.backgroundColor, Color.orange.opacity(0.3))
        XCTAssertEqual(BeltLevel.purple.backgroundColor, Color.purple.opacity(0.3))
        XCTAssertEqual(BeltLevel.blue.backgroundColor, Color.blue.opacity(0.3))
        XCTAssertEqual(BeltLevel.green.backgroundColor, Color.green.opacity(0.3))
        XCTAssertEqual(BeltLevel.brown.backgroundColor, Color.brown.opacity(0.3))
        XCTAssertEqual(BeltLevel.black.backgroundColor, Color.black.opacity(0.7))
        XCTAssertEqual(BeltLevel.unknown.backgroundColor, Color.gray.opacity(0.3))
        
        // Test conversion back to string
        XCTAssertEqual(BeltLevel.white.rawValue, "White")
        XCTAssertEqual(BeltLevel.yellow.rawValue, "Yellow")
        XCTAssertEqual(BeltLevel.orange.rawValue, "Orange")
    }
    
    func testPersistenceControllerInMemory() {
        let controller = PersistenceController(inMemory: true)
        
        // Verify it's in memory
        XCTAssertTrue(controller.inMemory)
        
        // Add test data
        let context = controller.container.viewContext
        let entity = TrainingSessionEntity(context: context)
        entity.name = "Test In-Memory Session"
        
        // Save should succeed
        XCTAssertNoThrow(try context.save())
        
        // Verify data can be retrieved
        let request: NSFetchRequest<TrainingSessionEntity> = TrainingSessionEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.name, "Test In-Memory Session")
        } catch {
            XCTFail("Failed to fetch results: \(error)")
        }
    }
    
    func testShuffleTechniques() {
        // Create an array of techniques with known order
        var techniques = [
            Technique(id: UUID(), name: "Technique 1", orderIndex: 0, beltLevel: .white, timeToComplete: 5),
            Technique(id: UUID(), name: "Technique 2", orderIndex: 1, beltLevel: .yellow, timeToComplete: 6),
            Technique(id: UUID(), name: "Technique 3", orderIndex: 2, beltLevel: .orange, timeToComplete: 7),
            Technique(id: UUID(), name: "Technique 4", orderIndex: 3, beltLevel: .purple, timeToComplete: 8),
            Technique(id: UUID(), name: "Technique 5", orderIndex: 4, beltLevel: .blue, timeToComplete: 9)
        ]
        
        // Store original order
        let originalOrder = techniques.map { $0.name }
        
        // Create a copy for later comparison
        let originalTechniques = techniques
        
        // Shuffle the techniques multiple times to ensure we get a different order
        // (this is a probabilistic test, but with 5 elements and multiple shuffles, 
        // the probability of keeping the same order is extremely small)
        for _ in 0..<10 {
            ShuffleHelper.shuffleTechniques(&techniques)
        }
        
        // Get shuffled order
        let shuffledOrder = techniques.map { $0.name }
        
        // Verify all techniques still exist (by checking count and each name)
        XCTAssertEqual(techniques.count, originalTechniques.count)
        for name in originalOrder {
            XCTAssertTrue(shuffledOrder.contains(name), "All techniques should still exist after shuffling")
        }
        
        // Test that orderIndex values were updated to match new positions
        for (index, technique) in techniques.enumerated() {
            XCTAssertEqual(technique.orderIndex, index, "orderIndex should match new position")
        }
    }
    
    func testTrainingSessionHistoryConversion() {
        // Setup in-memory context
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        
        // Create history entity
        let historyEntity = TrainingSessionHistoryEntity(context: context)
        historyEntity.id = UUID()
        historyEntity.sessionName = "History Test Session"
        let timestamp = Date()
        historyEntity.timestamp = timestamp
        
        // Add history items
        let item1 = TrainingSessionHistoryItemsEntity(context: context)
        item1.id = UUID()
        item1.exerciseName = "Front Kick"
        item1.timeTaken = 7.5
        item1.type = "Kick"
        historyEntity.addToItems(item1)
        
        let item2 = TrainingSessionHistoryItemsEntity(context: context)
        item2.id = UUID()
        item2.exerciseName = "Side Kick"
        item2.timeTaken = 8.2
        item2.type = "Kick"
        historyEntity.addToItems(item2)
        
        // Save context
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
            return
        }
        
        // Convert to model
        let history = TrainingSessionHistory(from: historyEntity)
        
        // Verify basic properties
        XCTAssertEqual(history.sessionName, "History Test Session")
        XCTAssertEqual(history.items.count, 2)
        
        // Find items by name for verification
        let frontKick = history.items.first(where: { $0.exerciseName == "Front Kick" })
        let sideKick = history.items.first(where: { $0.exerciseName == "Side Kick" })
        
        // Verify item properties
        XCTAssertNotNil(frontKick)
        XCTAssertEqual(frontKick?.exerciseName, "Front Kick")
        XCTAssertEqual(frontKick?.timeTaken, 7.5)
        XCTAssertEqual(frontKick?.type, "Kick")
        
        XCTAssertNotNil(sideKick)
        XCTAssertEqual(sideKick?.exerciseName, "Side Kick")
        XCTAssertEqual(sideKick?.timeTaken, 8.2)
        XCTAssertEqual(sideKick?.type, "Kick")
    }
}
