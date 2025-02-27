//
//  Kata_PulseTests.swift
//  Kata PulseTests
//
//  Created by Aaron Addleman on 9/20/24.
//

import XCTest
@testable import Kata_Pulse

final class Kata_PulseTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
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
        // Set up in-memory context and data manager for testing
        let persistenceController = PersistenceController(inMemory: true)
        let context = persistenceController.container.viewContext
        let dataManager = DataManager(persistenceController: persistenceController)
        
        // Create a new training session entity
        let sessionEntity = TrainingSessionEntity(context: context)
        sessionEntity.id = UUID()
        sessionEntity.name = "Test Session"
        
        // Get the first two techniques from the predefined techniques list
        let firstTechnique = predefinedTechniques[0]  // Kimono Grab
        let secondTechnique = predefinedTechniques[1] // Striking Asp A
        
        // Create technique entities with selected flag set to true
        let firstTechniqueEntity = TechniqueEntity(context: context)
        firstTechniqueEntity.id = firstTechnique.id
        firstTechniqueEntity.name = firstTechnique.name
        firstTechniqueEntity.beltLevel = firstTechnique.beltLevel.rawValue
        firstTechniqueEntity.timeToComplete = Int16(firstTechnique.timeToComplete)
        firstTechniqueEntity.orderIndex = 0
        firstTechniqueEntity.isSelected = true
        
        let secondTechniqueEntity = TechniqueEntity(context: context)
        secondTechniqueEntity.id = secondTechnique.id
        secondTechniqueEntity.name = secondTechnique.name
        secondTechniqueEntity.beltLevel = secondTechnique.beltLevel.rawValue
        secondTechniqueEntity.timeToComplete = Int16(secondTechnique.timeToComplete)
        secondTechniqueEntity.orderIndex = 1
        secondTechniqueEntity.isSelected = true
        
        // Add techniques to the session in specific order
        sessionEntity.addToSelectedTechniques(firstTechniqueEntity)
        sessionEntity.addToSelectedTechniques(secondTechniqueEntity)
        
        // Save context
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }
        
        // Load the techniques from the session using DataManager
        let techniques = dataManager.fetchTechniques(for: sessionEntity)
        
        // Test assertions
        XCTAssertEqual(techniques.count, 2, "Should have exactly 2 techniques")
        
        // Sort by order index to ensure correct order
        let sortedTechniques = techniques.sorted(by: { $0.orderIndex < $1.orderIndex })
        
        // Verify first technique
        XCTAssertEqual(sortedTechniques[0].name, "Kimono Grab", "First technique should be Kimono Grab")
        XCTAssertEqual(sortedTechniques[0].orderIndex, 0, "First technique should have orderIndex 0")
        XCTAssertTrue(sortedTechniques[0].isSelected, "First technique should be selected")
        
        // Verify second technique
        XCTAssertEqual(sortedTechniques[1].name, "Striking Asp A", "Second technique should be Striking Asp A")
        XCTAssertEqual(sortedTechniques[1].orderIndex, 1, "Second technique should have orderIndex 1")
        XCTAssertTrue(sortedTechniques[1].isSelected, "Second technique should be selected")
        
        // Check converted model as well
        let session = convertToTrainingSession(from: sessionEntity)
        
        // Verify the techniques in the converted model
        XCTAssertEqual(session.techniques.count, 2, "Converted session should have 2 techniques")
        XCTAssertEqual(session.techniques[0].name, "Kimono Grab", "First technique in converted session should be Kimono Grab")
        XCTAssertEqual(session.techniques[1].name, "Striking Asp A", "Second technique in converted session should be Striking Asp A")
    }

    func testCreateTrainingSessionEntity() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let session = TrainingSessionEntity(context: context)
        session.name = "Test Session"
        session.timeBetweenTechniques = 10

        XCTAssertEqual(session.name, "Test Session")
        XCTAssertEqual(session.timeBetweenTechniques, 10)
    }


    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
