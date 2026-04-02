import Foundation

struct ProfileRowState {
    let canMakeActive: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let canDeleteProfiles: Bool
    let makeActiveHelpText: String
    let moveUpHelpText: String
    let moveDownHelpText: String
    let deleteHelpText: String
}

struct ProfileSettingsRules {
    let profiles: [PlayerProfile]
    let selectedProfileID: String
    let gameInProgress: Bool

    var canCreateProfiles: Bool { gameInProgress == false }
    var canRenameProfiles: Bool { gameInProgress == false }
    var canReorderProfiles: Bool { gameInProgress == false }
    var canDeleteProfiles: Bool { gameInProgress == false && profiles.count > 1 }

    func createProfileHelpText() -> String {
        helpText(
            defaultKey: "profiles.new.help",
            disabledKey: "profiles.disabled.during_game",
            isDisabled: canCreateProfiles == false
        )
    }

    func editProfileHelpText() -> String {
        helpText(
            defaultKey: "profiles.name.help",
            disabledKey: "profiles.disabled.during_game",
            isDisabled: canRenameProfiles == false
        )
    }

    func rowState(for profile: PlayerProfile) -> ProfileRowState {
        let canMakeActive = profile.id != selectedProfileID
        let canMoveUp = isFirstProfile(profile) == false
        let canMoveDown = isLastProfile(profile) == false

        let makeActiveHelpText: String
        if canRenameProfiles == false {
            makeActiveHelpText = localized("profiles.disabled.during_game")
        } else if canMakeActive == false {
            makeActiveHelpText = localized("profiles.make_active.disabled.already")
        } else {
            makeActiveHelpText = localized("profiles.make_active.help")
        }

        let moveUpHelpText: String
        if canReorderProfiles == false {
            moveUpHelpText = localized("profiles.disabled.during_game")
        } else if canMoveUp == false {
            moveUpHelpText = localized("profiles.reorder.disabled.top")
        } else {
            moveUpHelpText = localized("profiles.reorder.up")
        }

        let moveDownHelpText: String
        if canReorderProfiles == false {
            moveDownHelpText = localized("profiles.disabled.during_game")
        } else if canMoveDown == false {
            moveDownHelpText = localized("profiles.reorder.disabled.bottom")
        } else {
            moveDownHelpText = localized("profiles.reorder.down")
        }

        let deleteHelpText: String
        if gameInProgress {
            deleteHelpText = localized("profiles.disabled.during_game")
        } else if canDeleteProfiles == false {
            deleteHelpText = localized("profiles.delete.disabled.single")
        } else {
            deleteHelpText = localized("profiles.delete.help")
        }

        return ProfileRowState(
            canMakeActive: canMakeActive,
            canMoveUp: canMoveUp,
            canMoveDown: canMoveDown,
            canDeleteProfiles: canDeleteProfiles,
            makeActiveHelpText: makeActiveHelpText,
            moveUpHelpText: moveUpHelpText,
            moveDownHelpText: moveDownHelpText,
            deleteHelpText: deleteHelpText
        )
    }

    private func helpText(defaultKey: String, disabledKey: String, isDisabled: Bool) -> String {
        isDisabled ? localized(disabledKey) : localized(defaultKey)
    }

    private func isFirstProfile(_ profile: PlayerProfile) -> Bool {
        profiles.first?.id == profile.id
    }

    private func isLastProfile(_ profile: PlayerProfile) -> Bool {
        profiles.last?.id == profile.id
    }
}
