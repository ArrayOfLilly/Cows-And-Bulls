import Testing
import Foundation
@testable import Cows___Bulls

@MainActor
@Suite("Profile Settings Store Tests")
struct ProfileSettingsStoreTests {
    private func setupDefaults() -> UserDefaults {
        let suiteName = "ProfileSettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("Settings are isolated per profile")
    func settingsIsolation() {
        let defaults = setupDefaults()
        let store = ProfileSettingsStore(userDefaults: defaults)

        store.setActiveProfileId("A")
        var aSettings = store.settings
        aSettings.maximumGuesses = 12
        store.settings = aSettings

        store.setActiveProfileId("B")
        #expect(store.settings.maximumGuesses == ProfileSettings.default.maximumGuesses)

        store.setActiveProfileId("A")
        #expect(store.settings.maximumGuesses == 12)
    }

    @Test("Legacy AppStorage values migrate into first profile")
    func legacyMigration() {
        let defaults = setupDefaults()
        defaults.set(7, forKey: "maximumGuesses")
        defaults.set(true, forKey: "enableHardMode")
        defaults.set("Bull9", forKey: "selectedBullAssetName")
        defaults.set("Cow9", forKey: "selectedCowAssetName")

        let store = ProfileSettingsStore(userDefaults: defaults)
        store.setActiveProfileId("A")

        #expect(store.settings.maximumGuesses == 7)
        #expect(store.settings.enableHardMode == true)
        #expect(store.settings.selectedBullAssetName == "Bull9")
        #expect(store.settings.selectedCowAssetName == "Cow9")
    }

    @Test("Deleting profile data resets settings to defaults")
    func deleteProfileDataResets() {
        let defaults = setupDefaults()
        let store = ProfileSettingsStore(userDefaults: defaults)

        store.setActiveProfileId("A")
        var settings = store.settings
        settings.enableRepeats = true
        store.settings = settings

        store.deleteProfileData(profileId: "A")
        store.setActiveProfileId("A")

        #expect(store.settings == ProfileSettings.default)
    }

    @Test("Deleting another profile does not affect current settings")
    func deleteOtherProfileDoesNotAffectCurrent() {
        let defaults = setupDefaults()
        let store = ProfileSettingsStore(userDefaults: defaults)

        store.setActiveProfileId("A")
        var aSettings = store.settings
        aSettings.showGuessCount = true
        store.settings = aSettings

        store.setActiveProfileId("B")
        store.deleteProfileData(profileId: "A")

        #expect(store.settings == ProfileSettings.default)

        store.setActiveProfileId("A")
        #expect(store.settings == ProfileSettings.default)
    }

    @Test("Corrupted stored data falls back to defaults")
    func corruptedDataFallsBack() {
        let defaults = setupDefaults()
        let key = "profile.settings.A"
        defaults.set(Data([0xFF, 0x00, 0xAB]), forKey: key)

        let store = ProfileSettingsStore(userDefaults: defaults)
        store.setActiveProfileId("A")

        #expect(store.settings == ProfileSettings.default)
    }
}
