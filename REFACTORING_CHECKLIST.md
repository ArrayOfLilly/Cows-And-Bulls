# Refactoring Checklist

## Immediate Next Steps

- [~] Szedd ki a visszatérő szabálylogikát computed property-kbe a `SettingsView`-ban.
  Már megvan:
  - `canEditGameplaySettings`
  - `canCreateProfiles`
  - `canRenameProfiles`
  - `canReorderProfiles`
  - `canDeleteProfiles`
  - `answerLengthHasValidationError`
  - `selectedTheme`
  Még hátra van:
  - a nevek továbbvitele a kisebb extracted subview-k felé
  - a profiles körüli helper döntések további egyszerűsítése, ha a jelenlegi `ProfileRowState` még nem elég
- [x] Adj stabil accessibility identifier-eket a fontos settings vezérlőknek.
- [~] Vezesd be a közös kis UI elemeket:
  - [x] `SettingsHelpCaption`
  - [x] `SettingsSliderRow`
  - [ ] `SettingsSectionTitle`
  - [x] `SettingsLockedNotice`
  - [x] `SettingsPercentSliderRow`
- [~] Tisztítsd a profiles helper logikát, ha még túl zajos.
  Már megvan:
  - [x] a profilsoronkénti döntések `ProfileRowState`-ba húzása
  Még hátra lehet:
  - [ ] külön `ProfileEditorState` vagy további action-helper, ha ez a rész újra nő
- [x] Döntsd el, hogy az `animalThemes` maradjon-e helyben vagy menjen külön fájlba.
  Megoldás:
  - [x] külön modellfájlba került: `Models/AnimalTheme.swift`

## Validation After Each Step

- [x] `SettingsView.swift` diagnosztika
- [x] teljes build
- [ ] `CowsAndBullsUITests/testSmokeGameScreen()`
- [x] célzott settings UI tesztek

## Important Guardrails

- [ ] Ne kerüljön vissza az auto-restart settings változásra.
- [ ] A gameplay beállítások maradjanak lockolva futó játék alatt.
- [ ] A profilműveletek maradjanak tiltva futó játék alatt.
- [ ] Az első gépelés indítsa a játékot, ne a launch vagy profilváltás.
- [ ] Ne kerüljön üzleti logika vissza nagy SwiftUI `body` blokkokba.

## Nice To Have

- [~] Settings UI tesztek a disabled state-ekre
  Már megvan:
  - [x] gameplay settings lock active game alatt
  - [x] profile create lock active game alatt
  - [x] language change restart prompt
  - [x] theme selection semantic state update
  Még hátra lehet:
  - [ ] profile reorder buttons explicit disabled-state tesztje
- [x] külön fájlokba bontani a settings nézeteket, ha még mindig túl nagy a fájl
  Megoldás:
  - [x] `Views/SettingsSupportViews.swift`
  - [x] `Views/SettingsTabViews.swift`
  - [x] `Views/SettingsProfilesViews.swift`
  - [x] `SettingsView.swift` kompozíciós réteggé tisztítva
- [ ] `ProfileEditorState` bevezetése, ha a profiles szerkesztési állapot tovább nő
