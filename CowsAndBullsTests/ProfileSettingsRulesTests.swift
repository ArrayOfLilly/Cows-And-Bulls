import Testing
@testable import Cows___Bulls

@Suite("Profile Settings Rules Tests")
struct ProfileSettingsRulesTests {
    private func makeProfile(id: String, name: String) -> PlayerProfile {
        PlayerProfile(id: id, name: name, createdAt: .distantPast)
    }

    @Test("Boundary rows expose correct reorder state")
    func boundaryRowState() {
        let profiles = [
            makeProfile(id: "A", name: "Alpha"),
            makeProfile(id: "B", name: "Bravo"),
            makeProfile(id: "C", name: "Charlie")
        ]
        let rules = ProfileSettingsRules(
            profiles: profiles,
            selectedProfileID: "A",
            gameInProgress: false
        )

        let firstRow = rules.rowState(for: profiles[0])
        let middleRow = rules.rowState(for: profiles[1])
        let lastRow = rules.rowState(for: profiles[2])

        #expect(firstRow.canMoveUp == false)
        #expect(firstRow.canMoveDown == true)
        #expect(middleRow.canMoveUp == true)
        #expect(middleRow.canMoveDown == true)
        #expect(lastRow.canMoveUp == true)
        #expect(lastRow.canMoveDown == false)
        #expect(firstRow.canMakeActive == false)
        #expect(middleRow.canMakeActive == true)
    }

    @Test("Active game locks profile editing actions")
    func activeGameLocksProfileActions() {
        let profiles = [
            makeProfile(id: "A", name: "Alpha"),
            makeProfile(id: "B", name: "Bravo")
        ]
        let rules = ProfileSettingsRules(
            profiles: profiles,
            selectedProfileID: "A",
            gameInProgress: true
        )

        let row = rules.rowState(for: profiles[1])

        #expect(rules.canCreateProfiles == false)
        #expect(rules.canRenameProfiles == false)
        #expect(rules.canReorderProfiles == false)
        #expect(rules.canDeleteProfiles == false)
        #expect(row.moveUpHelpText == localized("profiles.disabled.during_game"))
        #expect(row.moveDownHelpText == localized("profiles.disabled.during_game"))
        #expect(row.deleteHelpText == localized("profiles.disabled.during_game"))
        #expect(row.makeActiveHelpText == localized("profiles.disabled.during_game"))
    }
}
