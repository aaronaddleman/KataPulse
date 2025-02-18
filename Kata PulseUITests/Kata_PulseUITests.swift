//
//  Kata_PulseUITests.swift
//  Kata PulseUITests
//
//  Created by Aaron Addleman on 9/20/24.
//

import XCTest

final class Kata_PulseUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testOpenCreateTrainingSessionView() {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Sessions tab if using TabView
        app.tabBars.buttons["Sessions"].tap()

        // Tap the "+" button to open CreateTrainingSessionView
        let createButton = app.buttons["CreateTrainingSessionButton"]
        XCTAssertTrue(createButton.exists, "Create Training Session button should exist")
        createButton.tap()

        // Verify that the CreateTrainingSessionView appeared
        let createSessionTextField = app.textFields["Session Name"]
        XCTAssertTrue(createSessionTextField.waitForExistence(timeout: 2), "Session Name text field should appear")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
