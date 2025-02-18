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
        let context = PersistenceController.shared.container.viewContext
        let entity = TrainingSessionEntity(context: context)

        let technique1 = TechniqueEntity(context: context)
        technique1.name = "Technique 1"
        technique1.orderIndex = 0

        let technique2 = TechniqueEntity(context: context)
        technique2.name = "Technique 2"
        technique2.orderIndex = 1

        entity.addToSelectedTechniques(technique1)
        entity.addToSelectedTechniques(technique2)

        let session = convertToTrainingSession(from: entity)

        XCTAssertEqual(session.techniques[0].name, "Technique 1")
        XCTAssertEqual(session.techniques[1].name, "Technique 2")
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
