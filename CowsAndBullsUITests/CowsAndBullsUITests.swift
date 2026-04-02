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

        let gameTabButton = app.buttons["Game"]
        if gameTabButton.waitForExistence(timeout: 2) {
            gameTabButton.click()
        }

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))

        let submitButton = app.descendants(matching: .any).matching(identifier: "submitGuessButton").firstMatch
        XCTAssertTrue(submitButton.waitForExistence(timeout: 2))

        guessField.click()
        typeAndReplace(app: app, text: "1234")
        submitButton.click()

        let guessCountState = app.descendants(matching: .any).matching(identifier: "gameGuessCountState").firstMatch
        XCTAssertTrue(guessCountState.waitForExistence(timeout: 2))
        let guessesRecorded = NSPredicate(format: "value == %@", "1")
        expectation(for: guessesRecorded, evaluatedWith: guessCountState)
        waitForExpectations(timeout: 5)

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

        let celebrationScene = app.descendants(matching: .any).matching(identifier: "victoryCelebrationScene").firstMatch
        _ = celebrationScene.waitForExistence(timeout: 1)

        let celebrationCow = app.descendants(matching: .any).matching(identifier: "victoryCelebrationCow").firstMatch
        _ = celebrationCow.waitForExistence(timeout: 1)

        let winAlert = app.sheets.firstMatch
        XCTAssertTrue(winAlert.waitForExistence(timeout: 8))

        let winAlertButton = winAlert.buttons["OK"]
        XCTAssertTrue(winAlertButton.waitForExistence(timeout: 8))

        winAlertButton.click()

        if celebrationScene.exists {
            let disappeared = NSPredicate(format: "exists == false")
            expectation(for: disappeared, evaluatedWith: celebrationScene)
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

        let celebrationScene = app.descendants(matching: .any).matching(identifier: "victoryCelebrationScene").firstMatch
        _ = celebrationScene.waitForExistence(timeout: 1)

        let celebrationCow = app.descendants(matching: .any).matching(identifier: "victoryCelebrationCow").firstMatch
        _ = celebrationCow.waitForExistence(timeout: 1)

        let winAlert = app.sheets.firstMatch
        XCTAssertTrue(winAlert.waitForExistence(timeout: 8))

        let disappeared = NSPredicate(format: "exists == false")
        expectation(for: disappeared, evaluatedWith: celebrationScene)
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

    func testFirstTypingStartsGameInsteadOfLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launch()

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let gameTab = app.buttons["settingsOpenGameTab"]
        XCTAssertTrue(gameTab.waitForExistence(timeout: 2))
        gameTab.click()

        let celebrationToggle = app.descendants(matching: .any).matching(identifier: "settingsEnableCelebrationToggle").firstMatch
        XCTAssertTrue(celebrationToggle.waitForExistence(timeout: 2))
        XCTAssertTrue(celebrationToggle.isEnabled)

        closeFrontWindow(app: app)

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))
        guessField.click()
        app.typeText("1")

        openSettings(app: app)
        XCTAssertTrue(celebrationToggle.waitForExistence(timeout: 2))

        let disabledPredicate = NSPredicate(format: "enabled == false")
        expectation(for: disabledPredicate, evaluatedWith: celebrationToggle)
        waitForExpectations(timeout: 2)
        XCTAssertFalse(celebrationToggle.isEnabled)
    }

    func testSettingsProfilesControlsLockDuringActiveGame() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launchEnvironment["UITEST_SETTINGS_INITIAL_TAB"] = "profiles"
        app.launch()

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))

        guessField.click()
        app.typeText("1")

        openSettings(app: app)

        let selectedTabState = app.descendants(matching: .any).matching(identifier: "settingsSelectedTabState").firstMatch
        XCTAssertTrue(selectedTabState.waitForExistence(timeout: 2))
        XCTAssertEqual(selectedTabState.value as? String, "profiles")

        let profilesState = app.descendants(matching: .any).matching(identifier: "settingsProfilesState").firstMatch
        XCTAssertTrue(profilesState.waitForExistence(timeout: 2))
        let lockedState = NSPredicate(format: "value BEGINSWITH %@", "locked")
        expectation(for: lockedState, evaluatedWith: profilesState)
        waitForExpectations(timeout: 2)
    }

    func testSettingsLanguageChangeShowsRestartPrompt() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "system"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launchEnvironment["UITEST_SETTINGS_INITIAL_TAB"] = "language"
        app.launch()

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let selectedTabState = app.descendants(matching: .any).matching(identifier: "settingsSelectedTabState").firstMatch
        XCTAssertTrue(selectedTabState.waitForExistence(timeout: 2))
        XCTAssertEqual(selectedTabState.value as? String, "language")

        let englishButton = app.descendants(matching: .any).matching(identifier: "settingsSelectEnglishLanguageForTest").firstMatch
        XCTAssertTrue(englishButton.waitForExistence(timeout: 2))
        englishButton.click()

        let restartDialog = app.sheets.firstMatch
        XCTAssertTrue(restartDialog.waitForExistence(timeout: 2))

        let laterButton = restartDialog.buttons["Later"]
        XCTAssertTrue(laterButton.waitForExistence(timeout: 2))
        laterButton.click()
    }

    func testSettingsLanguageChangeDoesNotRestartWhenChoosingLater() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "system"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launchEnvironment["UITEST_SETTINGS_INITIAL_TAB"] = "language"
        app.launch()

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let englishButton = app.descendants(matching: .any).matching(identifier: "settingsSelectEnglishLanguageForTest").firstMatch
        XCTAssertTrue(englishButton.waitForExistence(timeout: 2))
        englishButton.click()

        let restartDialog = app.sheets.firstMatch
        XCTAssertTrue(restartDialog.waitForExistence(timeout: 2))

        let laterButton = restartDialog.buttons["Later"]
        XCTAssertTrue(laterButton.waitForExistence(timeout: 2))
        laterButton.click()

        let selectedTabState = app.descendants(matching: .any).matching(identifier: "settingsSelectedTabState").firstMatch
        XCTAssertTrue(selectedTabState.waitForExistence(timeout: 2))
        XCTAssertEqual(selectedTabState.value as? String, "language")

        let gameTab = app.buttons["settingsOpenGameTab"]
        XCTAssertTrue(gameTab.waitForExistence(timeout: 2))
        gameTab.click()
        XCTAssertEqual(selectedTabState.value as? String, "game")
    }

    func testSettingsThemeSelectionUpdatesSelectedRow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launchEnvironment["UITEST_SETTINGS_INITIAL_TAB"] = "theme"
        app.launch()

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let selectedTabState = app.descendants(matching: .any).matching(identifier: "settingsSelectedTabState").firstMatch
        XCTAssertTrue(selectedTabState.waitForExistence(timeout: 2))
        XCTAssertEqual(selectedTabState.value as? String, "theme")

        let selectedThemeState = app.descendants(matching: .any).matching(identifier: "settingsSelectedThemeState").firstMatch
        XCTAssertTrue(selectedThemeState.waitForExistence(timeout: 2))

        let geometricButton = app.descendants(matching: .any).matching(identifier: "settingsSelectGeometricThemeForTest").firstMatch
        XCTAssertTrue(geometricButton.waitForExistence(timeout: 2))
        geometricButton.click()

        XCTAssertEqual(selectedThemeState.value as? String, "geometric")
    }

    func testBackupButtonsDisableDuringActiveGame() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launchEnvironment["UITEST_SETTINGS_INITIAL_TAB"] = "profiles"
        app.launch()

        let guessField = app.descendants(matching: .any).matching(identifier: "guessInputField").firstMatch
        XCTAssertTrue(guessField.waitForExistence(timeout: 2))
        guessField.click()
        app.typeText("1")

        openSettings(app: app)

        let backupState = app.descendants(matching: .any).matching(identifier: "settingsBackupTransferState").firstMatch
        XCTAssertTrue(backupState.waitForExistence(timeout: 2))
        XCTAssertEqual(backupState.value as? String, "disabled")
    }

    func testSettingsProfileReorderButtonsReflectBoundaryState() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launchEnvironment["UITEST_SETTINGS_INITIAL_TAB"] = "profiles"
        app.launchEnvironment["UITEST_PROFILE_NAMES"] = "UI Reorder Alpha|UI Reorder Bravo|UI Reorder Charlie"
        app.launch()

        openSettings(app: app)

        let settingsRoot = app.descendants(matching: .any).matching(identifier: "settingsRoot").firstMatch
        XCTAssertTrue(settingsRoot.waitForExistence(timeout: 2))

        let selectedTabState = app.descendants(matching: .any).matching(identifier: "settingsSelectedTabState").firstMatch
        XCTAssertTrue(selectedTabState.waitForExistence(timeout: 2))
        XCTAssertEqual(selectedTabState.value as? String, "profiles")

        let profilesState = app.descendants(matching: .any).matching(identifier: "settingsProfilesState").firstMatch
        XCTAssertTrue(profilesState.waitForExistence(timeout: 2))
        XCTAssertEqual(
            profilesState.value as? String,
            "editable|row0:up:disabled,down:enabled|row1:up:enabled,down:enabled|row2:up:enabled,down:disabled||order:UI Reorder Alpha|UI Reorder Bravo|UI Reorder Charlie"
        )
    }

    func testSettingsProfileReorderInteractionUpdatesOrder() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_FORCE_LANGUAGE"] = "en"
        app.launchEnvironment["UITEST_SETTINGS_TAB_SHORTCUTS"] = "1"
        app.launchEnvironment["UITEST_SETTINGS_INITIAL_TAB"] = "profiles"
        app.launchEnvironment["UITEST_PROFILE_NAMES"] = "UI Reorder Alpha|UI Reorder Bravo|UI Reorder Charlie"
        app.launch()

        openSettings(app: app)

        let selectedTabState = app.descendants(matching: .any).matching(identifier: "settingsSelectedTabState").firstMatch
        XCTAssertTrue(selectedTabState.waitForExistence(timeout: 2))
        XCTAssertEqual(selectedTabState.value as? String, "profiles")

        let profilesState = app.descendants(matching: .any).matching(identifier: "settingsProfilesState").firstMatch
        XCTAssertTrue(profilesState.waitForExistence(timeout: 2))
        XCTAssertEqual(
            profilesState.value as? String,
            "editable|row0:up:disabled,down:enabled|row1:up:enabled,down:enabled|row2:up:enabled,down:disabled||order:UI Reorder Alpha|UI Reorder Bravo|UI Reorder Charlie"
        )

        let moveUpButton = app.staticTexts["settingsMoveSecondProfileUpForTest"]
        XCTAssertTrue(moveUpButton.waitForExistence(timeout: 2))
        XCTAssertTrue(moveUpButton.isEnabled)
        moveUpButton.click()

        let updatedProfilesState = app.staticTexts["settingsProfilesState"]
        let expectedProfilesState = "editable|row0:up:disabled,down:enabled|row1:up:enabled,down:enabled|row2:up:enabled,down:disabled||order:UI Reorder Bravo|UI Reorder Alpha|UI Reorder Charlie"

        XCTAssertTrue(updatedProfilesState.waitForExistence(timeout: 2))
        let updatedStatePredicate = NSPredicate(format: "value == %@", expectedProfilesState)
        expectation(for: updatedStatePredicate, evaluatedWith: updatedProfilesState)
        waitForExpectations(timeout: 2)
        XCTAssertEqual(updatedProfilesState.value as? String, expectedProfilesState)
    }

    private func typeAndReplace(app: XCUIApplication, text: String) {
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(XCUIKeyboardKey.delete, modifierFlags: [])
        app.typeText(text)
    }

    private func openSettings(app: XCUIApplication) {
        app.typeKey(",", modifierFlags: .command)
    }

    private func closeFrontWindow(app: XCUIApplication) {
        app.typeKey("w", modifierFlags: .command)
    }
}
