//
//  SettingsProfilesViews.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct ProfileEditorState {
    var newProfileName = ""
    var profileNameDrafts: [String: String] = [:]
    var editingProfileIDs: Set<String> = []

    func draftName(for profile: PlayerProfile) -> String {
        profileNameDrafts[profile.id] ?? profile.name
    }

    mutating func setDraftName(_ name: String, for profile: PlayerProfile) {
        profileNameDrafts[profile.id] = name
    }

    mutating func beginEditing(_ profile: PlayerProfile) {
        editingProfileIDs.insert(profile.id)
    }

    mutating func endEditing(_ profile: PlayerProfile) {
        editingProfileIDs.remove(profile.id)
    }

    func isEditing(_ profile: PlayerProfile) -> Bool {
        editingProfileIDs.contains(profile.id)
    }

    mutating func syncDrafts(with profiles: [PlayerProfile]) {
        for profile in profiles where isEditing(profile) == false {
            profileNameDrafts[profile.id] = profile.name
        }
    }
}

struct SettingsProfilesTab: View {
    let profiles: [PlayerProfile]
    let selectedProfileID: String
    let newProfileName: Binding<String>
    let canEditSettings: Bool
    let draftBindingForProfileName: (PlayerProfile) -> Binding<String>
    let onCreateProfile: () -> Void
    let onBeginEditing: (PlayerProfile) -> Void
    let onEndEditing: (PlayerProfile) -> Void
    let onCommitProfileName: (PlayerProfile) -> Void
    let onMakeActive: (PlayerProfile) -> Void
    let onMoveUp: (PlayerProfile) -> Void
    let onMoveDown: (PlayerProfile) -> Void
    let onDelete: (PlayerProfile) -> Void
    let createProfileHelpText: String
    let editProfileHelpText: String
    let profileRowState: (PlayerProfile) -> ProfileRowState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfilesToolbarRow(
                newProfileName: newProfileName,
                canEditSettings: canEditSettings,
                createProfileHelpText: createProfileHelpText,
                onCreateProfile: onCreateProfile
            )

            List {
                ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                    let rowState = profileRowState(profile)
                    ProfileRowView(
                        profile: profile,
                        rowIndex: index,
                        isSelected: profile.id == selectedProfileID,
                        nameBinding: draftBindingForProfileName(profile),
                        canEditSettings: canEditSettings,
                        canDeleteProfiles: rowState.canDeleteProfiles,
                        canMakeActive: rowState.canMakeActive,
                        canMoveUp: rowState.canMoveUp,
                        canMoveDown: rowState.canMoveDown,
                        editProfileHelpText: editProfileHelpText,
                        makeActiveHelpText: rowState.makeActiveHelpText,
                        moveUpHelpText: rowState.moveUpHelpText,
                        moveDownHelpText: rowState.moveDownHelpText,
                        deleteHelpText: rowState.deleteHelpText,
                        onBeginEditing: { onBeginEditing(profile) },
                        onEndEditing: { onEndEditing(profile) },
                        onCommitProfileName: { onCommitProfileName(profile) },
                        onMakeActive: { onMakeActive(profile) },
                        onMoveUp: { onMoveUp(profile) },
                        onMoveDown: { onMoveDown(profile) },
                        onDelete: { onDelete(profile) }
                    )
                }
            }
        }
    }
}

struct ProfilesToolbarRow: View {
    let newProfileName: Binding<String>
    let canEditSettings: Bool
    let createProfileHelpText: String
    let onCreateProfile: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField(localized("profiles.new.placeholder"), text: newProfileName)
                .textFieldStyle(.roundedBorder)
                .disabled(canEditSettings == false)
                .help(createProfileHelpText)
                .accessibilityIdentifier("profilesNewNameField")

            Button(localized("profiles.new.action"), action: onCreateProfile)
                .disabled(canEditSettings == false)
                .help(createProfileHelpText)
                .accessibilityIdentifier("profilesCreateButton")

            Spacer()

            Text(localized("profiles.reorder.hint"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ProfileRowView: View {
    let profile: PlayerProfile
    let rowIndex: Int
    let isSelected: Bool
    let nameBinding: Binding<String>
    let canEditSettings: Bool
    let canDeleteProfiles: Bool
    let canMakeActive: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let editProfileHelpText: String
    let makeActiveHelpText: String
    let moveUpHelpText: String
    let moveDownHelpText: String
    let deleteHelpText: String
    let onBeginEditing: () -> Void
    let onEndEditing: () -> Void
    let onCommitProfileName: () -> Void
    let onMakeActive: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .help(localized("profiles.active.help"))
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }

            TextField(
                localized("profiles.name.placeholder"),
                text: nameBinding,
                onEditingChanged: { isEditing in
                    if isEditing {
                        onBeginEditing()
                    } else {
                        onEndEditing()
                    }
                },
                onCommit: onCommitProfileName
            )
            .textFieldStyle(.plain)
            .disabled(canEditSettings == false)
            .help(editProfileHelpText)

            Spacer()

            ProfileActionButtons(
                rowIndex: rowIndex,
                canEditSettings: canEditSettings,
                canDeleteProfiles: canDeleteProfiles,
                canMakeActive: canMakeActive,
                canMoveUp: canMoveUp,
                canMoveDown: canMoveDown,
                makeActiveHelpText: makeActiveHelpText,
                moveUpHelpText: moveUpHelpText,
                moveDownHelpText: moveDownHelpText,
                deleteHelpText: deleteHelpText,
                onMakeActive: onMakeActive,
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                onDelete: onDelete
            )
        }
        .accessibilityIdentifier("profileRow_\(rowIndex)")
        .accessibilityValue("moveUp:\(canMoveUp ? "enabled" : "disabled"),moveDown:\(canMoveDown ? "enabled" : "disabled")")
    }
}

struct ProfileActionButtons: View {
    let rowIndex: Int
    let canEditSettings: Bool
    let canDeleteProfiles: Bool
    let canMakeActive: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let makeActiveHelpText: String
    let moveUpHelpText: String
    let moveDownHelpText: String
    let deleteHelpText: String
    let onMakeActive: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(localized("profiles.make_active"), action: onMakeActive)
            .disabled(canEditSettings == false || canMakeActive == false)
            .help(makeActiveHelpText)

        Button(action: onMoveUp) {
            Image(systemName: "chevron.up")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(canEditSettings == false || canMoveUp == false)
        .help(moveUpHelpText)
        .accessibilityLabel("Move Profile Up")
        .accessibilityIdentifier("profileMoveUpButton_\(rowIndex)")

        Button(action: onMoveDown) {
            Image(systemName: "chevron.down")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(canEditSettings == false || canMoveDown == false)
        .help(moveDownHelpText)
        .accessibilityLabel("Move Profile Down")
        .accessibilityIdentifier("profileMoveDownButton_\(rowIndex)")

        Button(role: .destructive, action: onDelete) {
            Image(systemName: "trash")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(deleteHelpText)
        .disabled(canEditSettings == false || canDeleteProfiles == false)
    }
}
