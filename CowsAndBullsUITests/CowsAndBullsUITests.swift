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

    func testSettingsGameplayControlsLockDuringActiveGame() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launch()

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))

        guessField.click()
        app.typeText("1")

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let gameTab = app.buttons["settingsOpenGameTab"]
        XCTAssertTrue(gameTab.waitForExistence(timeout: 2))
        gameTab.click()

        let celebrationToggle = app.descendants(matching: .any).matching(identifier: "settingsEnableCelebrationToggle").firstMatch
        XCTAssertTrue(celebrationToggle.waitForExistence(timeout: 2))
        XCTAssertFalse(celebrationToggle.isEnabled)

        let maximumGuessesField = app.descendants(matching: .any).matching(identifier: "settingsMaximumGuessesField").firstMatch
        XCTAssertTrue(maximumGuessesField.waitForExistence(timeout: 2))
        XCTAssertFalse(maximumGuessesField.isEnabled)

        let soundTab = app.buttons["settingsOpenSoundTab"]
        XCTAssertTrue(soundTab.waitForExistence(timeout: 2))
        soundTab.click()

        let soundToggle = app.descendants(matching: .any).matching(identifier: "settingsSoundEffectsToggle").firstMatch
        XCTAssertTrue(soundToggle.waitForExistence(timeout: 2))
        XCTAssertTrue(soundToggle.isEnabled)
    }

    func testSettingsProfilesControlsLockDuringActiveGame() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launch()

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))

        guessField.click()
        app.typeText("1")

        openSettings(app: app)

        let profilesTab = app.buttons["settingsOpenProfilesTab"]
        XCTAssertTrue(profilesTab.waitForExistence(timeout: 2))
        profilesTab.click()

        let profilesContent = app.descendants(matching: .any).matching(identifier: "settingsProfilesTabContent").firstMatch
        XCTAssertTrue(profilesContent.waitForExistence(timeout: 2))

        let editabilityState = app.descendants(matching: .any).matching(identifier: "settingsProfilesEditabilityState").firstMatch
        XCTAssertTrue(editabilityState.waitForExistence(timeout: 2))
        XCTAssertEqual(editabilityState.value as? String, "locked")
    }

    func testSettingsLanguageChangeShowsRestartPrompt() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "system"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launch()

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let languageTab = app.buttons["settingsOpenLanguageTab"]
        XCTAssertTrue(languageTab.waitForExistence(timeout: 2))
        languageTab.click()

        let englishOption = app.radioButtons["English"]
        XCTAssertTrue(englishOption.waitForExistence(timeout: 2))
        englishOption.click()

        let restartDialog = app.sheets.firstMatch
        XCTAssertTrue(restartDialog.waitForExistence(timeout: 2))

        let laterButton = restartDialog.buttons["Later"]
        XCTAssertTrue(laterButton.waitForExistence(timeout: 2))
        laterButton.click()
    }

    func testSettingsThemeSelectionUpdatesSelectedRow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launch()

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let themeTab = app.buttons["settingsOpenThemeTab"]
        XCTAssertTrue(themeTab.waitForExistence(timeout: 2))
        themeTab.click()

        let classicRow = app.descendants(matching: .any).matching(identifier: "settingsThemeRow_classic").firstMatch
        let geometricRow = app.descendants(matching: .any).matching(identifier: "settingsThemeRow_geometric").firstMatch
        XCTAssertTrue(classicRow.waitForExistence(timeout: 2))
        XCTAssertTrue(geometricRow.waitForExistence(timeout: 2))

        let classicWasSelected = (classicRow.value as? String) == "selected"
        let targetRow = classicWasSelected ? geometricRow : classicRow
        let otherRow = classicWasSelected ? classicRow : geometricRow

        targetRow.click()

        XCTAssertEqual(targetRow.value as? String, "selected")
        XCTAssertEqual(otherRow.value as? String, "notSelected")
    }

    private func typeAndReplace(app: XCUIApplication, text: String) {
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(XCUIKeyboardKey.delete, modifierFlags: [])
        app.typeText(text)
    }

    private func openSettings(app: XCUIApplication) {
        app.typeKey(",", modifierFlags: .command)
    }
}
