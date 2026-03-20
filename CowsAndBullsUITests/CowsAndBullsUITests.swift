//
//  CowsAndBullsUITests.swift
//  CowsAndBullsUITests
//
//  Created by Ildikó Kasza on 2026. 03. 10..
//

import XCTest

final class CowsAndBullsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSmokeGameScreen() throws {
        let app = XCUIApplication()
        app.launch()

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))

        let submitButton = app.buttons["submitGuessButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 2))

        guessField.click()
        typeAndReplace(app: app, text: "1234")
        submitButton.click()

        let guessText = app.staticTexts["1234"]
        XCTAssertTrue(guessText.waitForExistence(timeout: 2))

        typeAndReplace(app: app, text: "11")
        submitButton.click()

        let fieldValue = guessField.value as? String
        XCTAssertEqual(fieldValue, "11")
    }

    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testVictoryCelebrationAppearsAndDismisses() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCED_ANSWER"] = "1234"
        app.launch()

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))

        let submitButton = app.buttons["submitGuessButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 2))

        guessField.click()
        typeAndReplace(app: app, text: "1234")
        submitButton.click()

        let celebrationCow = app.descendants(matching: .any).matching(identifier: "victoryCelebrationCow").firstMatch
        XCTAssertTrue(celebrationCow.waitForExistence(timeout: 2))

        let winAlert = app.sheets.firstMatch
        XCTAssertTrue(winAlert.waitForExistence(timeout: 4))

        let winAlertButton = winAlert.buttons["OK"]
        XCTAssertTrue(winAlertButton.waitForExistence(timeout: 4))

        winAlertButton.click()

        if celebrationCow.exists {
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: celebrationCow)
            waitForExpectations(timeout: 2)
        }
    }

    func testVictoryCelebrationAutoDismissesWithoutAlertInteraction() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCED_ANSWER"] = "1234"
        app.launch()

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))

        let submitButton = app.buttons["submitGuessButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 2))

        guessField.click()
        typeAndReplace(app: app, text: "1234")
        submitButton.click()

        let celebrationCow = app.descendants(matching: .any).matching(identifier: "victoryCelebrationCow").firstMatch
        XCTAssertTrue(celebrationCow.waitForExistence(timeout: 2))

        let winAlert = app.sheets.firstMatch
        XCTAssertTrue(winAlert.waitForExistence(timeout: 4))

        let disappeared = NSPredicate(format: "exists == false")
        expectation(for: disappeared, evaluatedWith: celebrationCow)
        waitForExpectations(timeout: 5)
    }

    private func typeAndReplace(app: XCUIApplication, text: String) {
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(XCUIKeyboardKey.delete, modifierFlags: [])
        app.typeText(text)
    }
}
