# Refactoring Plan

## Current Status

The project already has a cleaner separation than the original version:

- `ContentView` has been split into smaller subviews.
- Gameplay state is managed by `GameplayStore`.
- Session and timing state is managed by `GameSessionStore`.
- `SettingsView` has started to move toward a compositional structure.
- Victory celebration is now isolated behind a dedicated screen-level controller:
  - `Views/VictoryCelebrationWindowController.swift`
- Celebration can be toggled per profile via settings persistence.
- UI coverage now includes the victory celebration flow and its auto-dismiss behavior.

This document is the continuation plan if the ongoing refactor needs to be finished manually.

## Main Goal

Keep views focused on presentation and user interaction wiring.
Keep business rules and mutable state in stores or small action helpers.
Prefer small subviews with explicit inputs over large views that reach into multiple stores directly.
Push any non-trivial decision logic out of `View` files unless it is purely local UI presentation state.

## Architectural Direction

### What should live in stores

- gameplay state
- session state
- timer state
- profile list mutation
- profile settings persistence
- history persistence
- statistics calculation

### What should live in views

- layout
- bindings
- accessibility identifiers
- short UI-specific validation state
- dialog presentation state

### What should not stay in large view bodies

- repeated `disabled(...)` logic
- repeated help-text decision trees
- repeated asset-preview rows
- timer configuration binding boilerplate
- large inline row definitions

## Current Refactor Progress

### Already done

- `ContentView` split into:
  - `GameHeaderSection`
  - `ProfilePickerRow`
  - `TimerStatusBar`
  - `GameInputSection`
  - `GuessesListSection`
  - `GuessResultIconsView`
  - `GameFooterSection`
- `ContentView` game-screen rule computation started moving out of the view into:
  - `Models/GamePresentationRules.swift`
- `SettingsView` split into:
  - `SettingsFormContainer`
  - `SettingsGameTab`
  - `SettingsAdvancedTab`
  - `SettingsSoundTab`
  - `SettingsMusicTab`
  - `SettingsLanguageTab`
  - `SettingsThemeTab`
  - `ThemeRowView`
  - `SettingsProfilesTab`
  - `ProfilesToolbarRow`
  - `ProfileRowView`
  - `ProfileActionButtons`
- `LearnView` split into:
  - `LearnContentView`
  - `LearnSection`
  - `LearnObjectiveSection`
  - `LearnSkillsSection`
  - `LearnHowToPlaySection`
  - `LearnGuessExplanationSection`
  - `LearnStrategySection`
  - `LearnScoringSection`
  - `LearnOptionsSection`
- victory celebration moved out of `ContentView` into a dedicated AppKit-backed controller
- gameplay settings include an `enableCelebration` toggle
- UI tests cover:
  - celebration appears on win
  - celebration dismisses on alert action
  - celebration auto-dismisses without alert interaction
  - gameplay settings lock during an active game
  - profiles creation lock during an active game
  - language change shows restart prompt
  - theme selection exposes semantic selected-state updates

### Still worth doing

- finish extracting repeated rule computation out of `SettingsView`
- continue extracting remaining `ContentView` decision logic into store/helper types
- consider moving theme definitions out of the view file
- standardize settings row visuals
- consider adding a left-side table of contents to `LearnView` after the content structure is stable
- add more accessibility identifiers to settings controls if new controls appear
- add targeted UI tests for disabled-state behavior if more settings flows are added
- decide whether celebration timing/path should become user-configurable or remain hard-coded

## Recommended Next Steps

### Step 1: Normalize Settings Rules

Create computed properties in `SettingsView` for repeated decision logic.

Current progress:

- introduced named rule properties for gameplay/profile editability
- introduced `answerLengthHasValidationError`
- introduced `selectedTheme`
- introduced `ProfileRowState` so profile action booleans/help text are composed in one place
- introduced `ProfileEditorState` so profile drafts, editing membership, and new-profile input live in one place
- still worth shrinking the remaining `SettingsView` helper surface if profiles actions grow further

Recommended properties:

- `canCreateProfiles`
- `canRenameProfiles`
- `canReorderProfiles`
- `canDeleteProfiles`
- `canEditTimerSettings`
- `canEditGameplaySettings`
- `answerLengthHasValidationError`
- `selectedTheme`

Goal:
reduce inline booleans and make the body read like composition, not logic.

Current progress beyond settings:

- added `GamePresentationRules` for game-screen derived state
- moved score fairness, timer-active flags, profile-switch availability, and surrender availability out of `ContentView`
- moved game-mode text, profile-switch help text, and profile-selection branching out of `ContentView`
- moved pause/window-close guard decisions out of `ContentView`
- moved timeout, surrender, and loss-alert derived messaging/end-reason fallback out of `ContentView`
- introduced `GameCoordinator` for the first round of multi-store action orchestration
- introduced `GameTimerController` so timer tasks are no longer owned directly by `ContentView`
- simplified `AnimalIconStyle` into a fuller icon presentation style without an unused corner-radius parameter
- reduced `ContentView` game tab parameter noise with small context adapter structs for header/input/list/footer
- added targeted unit coverage in `GamePresentationRulesTests`

### Step 2: Introduce Small Shared UI Building Blocks

Create reusable view helpers inside `SettingsView.swift` first.
Only move them to separate files if they stay broadly reusable.

Recommended small components:

- `SettingsHelpCaption`
- `SettingsSliderRow`
- `SettingsPercentLabel`
- `SettingsSectionTitle`
- `SettingsLockedNotice`

Goal:
reduce repeated formatting and tighten visual consistency.

Current progress:

- introduced `SettingsHelpCaption`
- introduced `SettingsLockedNotice`
- introduced `SettingsSliderRow`
- introduced `SettingsPercentSliderRow`
- improved theme preview contrast with adaptive light/dark background fills
- `SettingsSectionTitle` added to normalize section headers across settings tabs

### Step 3: Decide Whether Theme Metadata Leaves the View

Right now `animalThemes` lives in `SettingsView`.
That is acceptable, but if more theme metadata appears, move it into one of:

- `Models/AnimalTheme.swift`
- `Logic/ThemeCatalog.swift`

Use a separate file if:

- theme list grows
- theme filtering or grouping is added
- preview metadata becomes richer

Keep it local if:

- it stays as a small, static lookup table

Current progress:

- completed: theme metadata moved to `Models/AnimalTheme.swift`
- `SettingsView` now consumes `AnimalTheme.all` instead of owning the catalog inline

### Step 4: Reduce `SettingsView` Local Mutation Surface

The view still owns:

- `previousLanguageCode`
- `showRestartPrompt`
- `newProfileName`
- `profilePendingDelete`
- `profileNameDrafts`
- `editingProfileIds`
- `answerLengthDraft`

That is mostly fine, but there are two candidates for extraction:

#### Candidate A: `ProfileEditorState`

Bundle:

- `profileNameDrafts`
- `editingProfileIds`

Possible shape:

```swift
struct ProfileEditorState {
    var drafts: [String: String] = [:]
    var editingIDs: Set<String> = []
}
```

This is optional.
Do it only if `SettingsView` keeps growing.

#### Candidate B: Answer-length input helper

If the answer-length text field grows more complex, move its behavior into:

- a tiny `AnswerLengthField` subview
- or a small local helper model

Do not extract this too early unless validation expands.

### Step 5: Add Accessibility Coverage for Settings

Important controls should get stable identifiers.

Recommended identifiers:

- `settingsMaximumGuessesField`
- `settingsAnswerLengthField`
- `settingsEnableCelebrationToggle`
- `settingsEnableRepeatsToggle`
- `settingsEnableHardModeToggle`
- `settingsShowGuessCountToggle`
- `settingsPerGuessTimerToggle`
- `settingsPerGuessTimerSlider`
- `settingsGameTimerToggle`
- `settingsGameTimerSlider`
- `settingsSoundEffectsToggle`
- `settingsSoundEffectsSlider`
- `settingsBackgroundMusicToggle`
- `settingsBackgroundMusicPicker`
- `settingsBackgroundMusicSlider`
- `settingsLanguagePicker`
- `settingsThemeRow_<theme-id>`
- `profilesNewNameField`
- `profilesCreateButton`

Goal:
make UI tests depend on explicit identifiers instead of fragile control-role lookup.

Current progress:

- identifiers added for the key gameplay, timer, audio, music, language, theme, and profile-create controls
- theme rows now expose semantic selected state for UI testing

### Step 6: Add UI Behavior Tests for Settings

Recommended UI tests:

- gameplay settings are disabled during an active game
- profile creation is disabled during an active game
- profile reorder buttons are disabled during an active game
- language change shows restart prompt
- theme selection updates the selected row visually or semantically

Keep these tests small and avoid over-asserting on macOS role types.
Prefer identifier-based queries.

Current progress:

- implemented active-game gameplay-lock test
- implemented active-game profiles-create-lock test
- implemented language restart prompt test
- implemented theme selection semantic state test
- implemented profile reorder boundary-state UI test
- implemented profile reorder interaction test via a dedicated UI-test hook that exercises the reorder action end-to-end
- introduced small UI-test hooks that avoid relying on localized tab titles
- stabilized the settings UI-test hook layer by exposing compact per-tab hook actions/state at the settings root overlay
- reran targeted settings UI tests after `ProfileEditorState` extraction and kept them green

### Step 7: Consider File Splitting

If `SettingsView.swift` still feels crowded after the above cleanup, split by domain:

- `Views/Settings/SettingsView.swift`
- `Views/Settings/SettingsGameTab.swift`
- `Views/Settings/SettingsAdvancedTab.swift`
- `Views/Settings/SettingsProfilesTab.swift`
- `Views/Settings/SettingsThemeTab.swift`

Do this only if navigation remains clear.
Do not split into too many microscopic files.

Current progress:

- completed with a medium-grained split instead of many tiny files
- current files:
  - `Views/SettingsView.swift`
  - `Views/SettingsSupportViews.swift`
  - `Views/SettingsTabViews.swift`
  - `Views/SettingsProfilesViews.swift`
- `SettingsView` now mainly owns store wiring, local state, dialogs, and action helpers

## Recommended Order If Continuing Manually

1. Add computed properties for repeated rules.
2. Add missing accessibility identifiers.
3. Introduce `SettingsHelpCaption` and `SettingsSliderRow`.
4. Clean up `profilesTab` helper rules if they still feel noisy.
5. Add 2-4 targeted UI tests for settings behavior.
6. Only then decide whether to split settings views into separate files.

## Validation Checklist

After each meaningful refactor step:

1. Run Xcode diagnostics for the changed file.
2. Build the project.
3. Run at least:
   - `CowsAndBullsUITests/testSmokeGameScreen()`
4. If settings behavior changes:
   - run relevant store tests too

## Guardrails

- Do not reintroduce auto-restart-on-settings-change logic.
- Keep gameplay-affecting settings locked while a game is running.
- Keep profile actions disabled during active games.
- Keep the first-input-starts-game behavior unchanged.
- Avoid moving business logic back into SwiftUI view bodies.

## Definition of Done

The refactor is in a good place when:

- `SettingsView` mainly composes child views
- child views receive explicit bindings and closures
- repeated rule logic is named and centralized
- key settings controls have stable accessibility identifiers
- build passes
- smoke UI test passes
- no gameplay/session regression is introduced
