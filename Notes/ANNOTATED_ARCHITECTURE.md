# Cows & Bulls - Annotated Architecture Guide

This guide explains **what to read first**, **why each file exists**, and highlights
special SwiftUI/AppKit patterns used in this project.

## Reading order (recommended)

1. `CowsAndBulls/CowsAndBullsApp.swift`
2. `CowsAndBulls/Views/ContentView.swift`
3. `CowsAndBulls/Logic/GameLogic.swift`
4. `CowsAndBulls/Models/HistoryStore.swift`
5. `CowsAndBulls/Views/Historyview.swift`
6. `CowsAndBulls/Views/StatisticView.swift`
7. `CowsAndBulls/Views/SettingsView.swift`
8. `CowsAndBulls/Logic/SoundPlayer.swift`
9. `CowsAndBulls/Logic/Localization.swift`
10. `CowsAndBulls/Views/LearnView.swift`

---

## 1) App entry and app-wide wiring

### File
`CowsAndBulls/CowsAndBullsApp.swift`

### Role
- Creates shared app state (`HistoryStore`)
- Injects locale and history into views
- Owns macOS command menu behavior
- Bridges SwiftUI and AppKit where SwiftUI is limited

### Non-trivial parts
- `CommandGroup(replacing: .appInfo/.help)`:
  overrides default macOS menu items.
- `showLocalizedAboutPanel()`:
  uses **AppKit** `NSApp.orderFrontStandardAboutPanel` for a customizable About panel.
- `openLearnWindow()`:
  uses **AppKit** `NSWindow` + `NSHostingController` for a dedicated help window.

### Why AppKit here?
SwiftUI does not expose the same level of control for these macOS-specific window/menu APIs.

---

## 2) Main gameplay screen

### File
`CowsAndBulls/Views/ContentView.swift`

### Role
- Runs one game session
- Handles guess input, validation, score, win/lose state
- Manages per-guess and total game timers
- Saves finished games to history

### Special SwiftUI features used
- `@FocusState`: keyboard focus control for TextField
- `.onSubmit`: Enter key submits guess
- `.alert`: win/lose dialogs

### Tricky implementation details
- **Timer tasks** (`Task` + `Task.sleep`) are cancellable and independent.
- UI state mutations from timer tasks happen on `MainActor`.
- `focusGuessField(selectAll:)` uses **AppKit** `NSApp.sendAction(#selector(NSText.selectAll))`
  because SwiftUI has no direct “select all text” API on macOS TextField.

---

## 3) Pure game rules and scoring

### File
`CowsAndBulls/Logic/GameLogic.swift`

### Role
- Pure logic only (no SwiftUI/AppKit dependencies)
- Generates answers
- Computes bulls/cows
- Validates guesses
- Calculates score with difficulty/performance multipliers

### Why this separation matters
- Keeps view code cleaner
- Easier testing and reuse
- One source of truth for game math

### Tricky part
- Score baseline uses `log10(combinations)` to keep values usable across different code lengths.

---

## 4) Persisted history model

### File
`CowsAndBulls/Models/HistoryStore.swift`

### Role
- Stores finished games (`HistoryItem`)
- Persists to `UserDefaults` as encoded JSON `Data`
- Publishes changes to UI

### Special pattern
- Injected `UserDefaults` + `storageKey` with `JSONEncoder/JSONDecoder`.
- This design improves testability by allowing isolated, per-test storage suites.

---

## 5) History tab

### File
`CowsAndBulls/Views/Historyview.swift`

### Role
- Shows game history cards
- Filter/sort controls
- Expandable row details for each game

### Special components
- `ContentUnavailableView`:
  native empty-state view.
- `GroupBox`:
  card-like container style with minimal custom code.
- `ToolbarItem(placement: .confirmationAction)`:
  expected trailing toolbar action on macOS.

### Tricky UI choices
- Expand/collapse uses combined transition:
  `.move(edge: .leading).combined(with: .opacity)`
- `.buttonStyle(.plain)` avoids default macOS button chrome inside custom row layout.

---

## 6) Statistics tab

### File
`CowsAndBulls/Views/StatisticView.swift`

### Role
- Aggregates history into summary metrics:
  wins/losses, rates, score averages, common settings.

### Notes
- Computed properties keep render code simple.
- `ContentUnavailableView` handles empty-history state.

---

## 7) Settings tabs

### File
`CowsAndBulls/Views/SettingsView.swift`

### Role
- Central settings for gameplay, timers, sound/music, language, themes

### Special features
- `TabView` as category-based settings container
- `confirmationDialog` for restart prompt
- `pickerStyle(.radioGroup)` for language selection
- `onChange` hooks to apply settings immediately

### Why AppKit here?
- `restartApplication()` uses `NSWorkspace` + `NSApp.terminate` to implement “Restart now”.

### Tricky pattern
- Dependent controls are disabled (not hidden), so users understand feature availability.

---

## 8) Audio service

### File
`CowsAndBulls/Logic/SoundPlayer.swift`

### Role
- Plays one-shot effects (`submit`, `win`, `lose`)
- Manages looping background music

### Tricky details
- Lazy loading and caching of `AVAudioPlayer` instances
- Dual source strategy: asset datasets first, then bundled audio files
- Fast path when current background track remains unchanged (only volume/play state update)

---

## 9) Localization helper

### File
`CowsAndBulls/Logic/Localization.swift`

### Role
- Central helper: `localized(key, args...)`
- Uses selected app language (`appLanguageCode`) to resolve bundle
- Performs locale-aware string formatting
- App text resources are maintained in `Localizable.xcstrings` (String Catalog)

### Important detail
- `String(format:locale:arguments:)` is used so formatted values follow selected language conventions.

---

## 10) Learn view

### File
`CowsAndBulls/Views/LearnView.swift`

### Role
- In-app teaching page
- Includes rules, scoring, option explanations
- Uses currently selected bull/cow image assets dynamically
- Uses namespaced localization keys (`learn.*`) maintained in String Catalog

### Custom mini pattern
- `optionRow(title, description)` helper keeps options in an aligned two-column layout.

### Accuracy note
- Learn text and HTML Help should stay in sync with `GameLogic.score` and
  `GameLogic.timeMultiplier` to avoid documentation drift.

---

## AppKit usage summary (in this project)

Used where SwiftUI alone is not enough (or not ergonomic) on macOS:
- About panel customization
- Explicit secondary window management
- App restart flow
- TextField select-all behavior
- NSApp activation/window focus behaviors

---

## Where to look when changing features

- **Game rules/score**: `Logic/GameLogic.swift`
- **Gameplay UI**: `Views/ContentView.swift`
- **Settings behavior**: `Views/SettingsView.swift`
- **History persistence**: `Models/HistoryStore.swift`
- **Localization strings**: `en.lproj/Localizable.strings`, `hu.lproj/Localizable.strings`
- **Audio**: `Logic/SoundPlayer.swift`

---

## Suggested next learning step

Read the files in the order at the top while following state flow:
1. where data is stored (`@AppStorage`, `HistoryStore`),
2. where UI mutates it (`ContentView`, `SettingsView`),
3. where logic computes outcomes (`GameLogic`),
4. where rendering reflects it (`HistoryView`, `StatisticView`).
