//
//  ProfileStore.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 03. 10..
//

import Foundation
internal import Combine

struct PlayerProfile: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var createdAt: Date
}

@MainActor
final class ProfileStore: ObservableObject {
    static let newProfileSelectionId = "__new_profile__"

    @Published private(set) var profiles: [PlayerProfile] = []
    @Published private(set) var selectedProfileId: String = ""

    private let userDefaults: UserDefaults
    private let profilesKey: String
    private let selectedKey: String

    init(
        userDefaults: UserDefaults = .standard,
        profilesKey: String = "profiles",
        selectedKey: String = "selectedProfileId"
    ) {
        self.userDefaults = userDefaults
        self.profilesKey = profilesKey
        self.selectedKey = selectedKey
        loadProfiles()
        ensureDefaultProfile()
        loadSelection()
    }

    var selectedProfile: PlayerProfile? {
        profiles.first { $0.id == selectedProfileId }
    }

    func selectProfile(id: String) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        selectedProfileId = id
        saveSelection()
    }

    func renameProfile(id: String, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        let updatedName = trimmedName.isEmpty ? nextDefaultProfileName() : trimmedName
        guard profiles[index].name != updatedName else { return }
        profiles[index].name = updatedName
        saveProfiles()
    }

    func deleteProfile(id: String) {
        guard profiles.count > 1 else { return }
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles.remove(at: index)
        if selectedProfileId == id, let first = profiles.first {
            selectedProfileId = first.id
            saveSelection()
        }
        saveProfiles()
    }

    func moveProfile(id: String, direction: Int) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < profiles.count else { return }
        let profile = profiles.remove(at: index)
        profiles.insert(profile, at: newIndex)
        saveProfiles()
    }

    @discardableResult
    func createProfile(named name: String?) -> PlayerProfile {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let profileName = trimmedName.isEmpty ? nextDefaultProfileName() : trimmedName
        let newProfile = PlayerProfile(
            id: UUID().uuidString,
            name: profileName,
            createdAt: Date()
        )
        profiles.append(newProfile)
        saveProfiles()
        selectProfile(id: newProfile.id)
        return newProfile
    }

    private func ensureDefaultProfile() {
        guard profiles.isEmpty else { return }
        let defaultProfile = PlayerProfile(
            id: UUID().uuidString,
            name: localized("profile.default_name.format", 1),
            createdAt: Date()
        )
        profiles = [defaultProfile]
        saveProfiles()
    }

    private func loadProfiles() {
        guard let data = userDefaults.data(forKey: profilesKey),
              let decoded = try? JSONDecoder().decode([PlayerProfile].self, from: data) else {
            profiles = []
            return
        }
        profiles = decoded
    }

    private func loadSelection() {
        if let storedId = userDefaults.string(forKey: selectedKey),
           profiles.contains(where: { $0.id == storedId }) {
            selectedProfileId = storedId
        } else if let first = profiles.first {
            selectedProfileId = first.id
            saveSelection()
        }
    }

    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            userDefaults.set(encoded, forKey: profilesKey)
        }
    }

    private func saveSelection() {
        userDefaults.set(selectedProfileId, forKey: selectedKey)
    }

    private func nextDefaultProfileName() -> String {
        var index = profiles.count + 1
        var candidate = localized("profile.default_name.format", index)
        let existingNames = Set(profiles.map { $0.name })
        while existingNames.contains(candidate) {
            index += 1
            candidate = localized("profile.default_name.format", index)
        }
        return candidate
    }
}
