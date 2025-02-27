//
//  Kata_PulseUITests.swift
//  Kata PulseUITests
//
//  Created by Aaron Addleman on 9/20/24.
//

import XCTest

final class Kata_PulseUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // Helper method to launch app with clean state
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        
        // Clear any previous app state and use in-memory Core Data
        app.launchArguments = [
            "--use-in-memory-core-data",
            "--reset-app-state"
        ]
        
        app.launch()
        return app
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = launchApp()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testOpenCreateTrainingSessionView() {
        let app = launchApp()

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
    
    func testCreateTrainingSessionWithTechniqueSelection() {
        let app = launchApp()

        // Navigate to the Sessions tab
        app.tabBars.buttons["Sessions"].tap()

        // Tap "+" button to open CreateTrainingSessionView
        let createButton = app.buttons["CreateTrainingSessionButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2), "Create Training Session button should exist")
        createButton.tap()

        // Enter "Testing Session" into the Session Name text field
        let sessionNameTextField = app.textFields["Session Name"]
        XCTAssertTrue(sessionNameTextField.waitForExistence(timeout: 2), "Session Name text field should appear")
        sessionNameTextField.tap()
        sessionNameTextField.typeText("Testing Session")

        // Tap "Modify Techniques"
        let modifyTechniquesButton = app.buttons["ModifyTechniquesButton"]
        XCTAssertTrue(modifyTechniquesButton.waitForExistence(timeout: 2), "Modify Techniques button should exist")
        modifyTechniquesButton.tap()

        // Select "Kimono Grab"
        let kimonoGrabCell = app.staticTexts["Kimono Grab"]
        XCTAssertTrue(kimonoGrabCell.waitForExistence(timeout: 2), "Kimono Grab cell should appear")
        kimonoGrabCell.tap()

        // Tap "Done" button to confirm selection and return
        let doneButton = app.buttons["SaveAndReturnButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2), "Save and Return button should exist")
        doneButton.tap()

        // Wait for form to be fully loaded, then scroll to find save button
        sleep(1) // Allow the UI to stabilize after returning
        
        // Scroll down a few times to reach the bottom where the save button should be
        for _ in 1...3 {
            app.swipeUp()
        }
        
        // Now check for the save button by accessibility identifier
        let saveButton = app.buttons["SaveSessionButton"]
        
        // If button not found by identifier, try to find it by text content
        if !saveButton.exists {
            print("Looking for Save button by text content since identifier failed")
            let saveButtonByText = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Save Session'")).firstMatch
            XCTAssertTrue(saveButtonByText.waitForExistence(timeout: 5), "Save Session button should exist")
            saveButtonByText.tap()
            return
        }
        
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save Session button should exist")
        
        // Ensure it's visible and tap it
        if !saveButton.isHittable {
            app.swipeUpUntilVisible(element: saveButton)
        }
        saveButton.tap()

        // Give the app some time to refresh the data
        sleep(2)
        
        // Verify that "Testing Session" is now in the list
        let testingSessionCell = app.staticTexts["Testing Session"]
        
        let exists = testingSessionCell.waitForExistence(timeout: 5)
        if !exists {
            print("Testing Session not found, checking available cells:")
            let allStaticTexts = app.staticTexts.allElementsBoundByIndex
            for text in allStaticTexts {
                print("Found text: \(text.label)")
            }
        }
        
        XCTAssertTrue(exists, "Testing Session should appear in the list")

        // ✅ Verify the technique count is displayed
        // First give UI a moment to update
        sleep(1)
        
        // Check for "Techniques: 1" as shown in TrainingSessionRow.swift
        let techniqueCountLabel = app.staticTexts["Techniques: 1"]
        
        // If not found, verify there's a problem by checking for the actual text
        if !techniqueCountLabel.exists {
            let predicate = NSPredicate(format: "label CONTAINS 'Techniques:'")
            let techniqueLabels = app.staticTexts.matching(predicate).allElementsBoundByIndex
            for label in techniqueLabels {
                print("Found technique label: \(label.label)")
            }
        }
        
        XCTAssertTrue(techniqueCountLabel.exists, "Session should display 'Techniques: 1'")

        // ✅ Swipe left on "Testing Session" to reveal "Edit"
        testingSessionCell.swipeLeft()
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Edit button should appear after swiping")
        editButton.tap()

        // ✅ Verify "Kimono Grab" is in the techniques list (no checkmark needed if using a reorder icon)
        let kimonoGrabInEditView = app.staticTexts["Kimono Grab"]
        XCTAssertTrue(kimonoGrabInEditView.waitForExistence(timeout: 2), "Kimono Grab should appear in the techniques list when editing")
    }



    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                launchApp()
            }
        }
    }
}


extension XCUIApplication {
    /// Scrolls up until an element is visible (hittable) or max swipes are reached.
    func swipeUpUntilVisible(element: XCUIElement, maxSwipes: Int = 10) {
        var swipes = 0
        
        while !element.isHittable && swipes < maxSwipes {
            swipeUp()
            swipes += 1
            
            // Short pause to let UI update
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
}
