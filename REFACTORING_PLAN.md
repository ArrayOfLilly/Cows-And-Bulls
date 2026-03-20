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
- victory celebration moved out of `ContentView` into a dedicated AppKit-backed controller
- gameplay settings include an `enableCelebration` toggle
- UI tests cover:
  - celebration appears on win
  - celebration dismisses on alert action
  - celebration auto-dismisses without alert interaction

### Still worth doing

- extract more rule computation out of `SettingsView`
- consider moving theme definitions out of the view file
- standardize settings row visuals
- add more accessibility identifiers to settings controls
- add targeted UI tests for disabled-state behavior
- decide whether celebration timing/path should become user-configurable or remain hard-coded

## Recommended Next Steps

### Step 1: Normalize Settings Rules

Create computed properties in `SettingsView` for repeated decision logic.

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

### Step 6: Add UI Behavior Tests for Settings

Recommended UI tests:

- gameplay settings are disabled during an active game
- profile creation is disabled during an active game
- profile reorder buttons are disabled during an active game
- language change shows restart prompt
- theme selection updates the selected row visually or semantically

Keep these tests small and avoid over-asserting on macOS role types.
Prefer identifier-based queries.

### Step 7: Consider File Splitting

If `SettingsView.swift` still feels crowded after the above cleanup, split by domain:

- `Views/Settings/SettingsView.swift`
- `Views/Settings/SettingsGameTab.swift`
- `Views/Settings/SettingsAdvancedTab.swift`
- `Views/Settings/SettingsProfilesTab.swift`
- `Views/Settings/SettingsThemeTab.swift`

Do this only if navigation remains clear.
Do not split into too many microscopic files.

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
