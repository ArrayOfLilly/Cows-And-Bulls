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
  - [x] `SettingsSectionTitle`
  - [x] `SettingsLockedNotice`
  - [x] `SettingsPercentSliderRow`
- [~] Tisztítsd a profiles helper logikát, ha még túl zajos.
  Már megvan:
  - [x] a profilsoronkénti döntések `ProfileRowState`-ba húzása
  - [x] a profiles szerkesztési lokális state egy `ProfileEditorState`-be húzása
  Még hátra lehet:
  - [ ] további action-helper vagy külön profile-domain file, ha ez a rész újra nő
- [x] Döntsd el, hogy az `animalThemes` maradjon-e helyben vagy menjen külön fájlba.
  Megoldás:
  - [x] külön modellfájlba került: `Models/AnimalTheme.swift`

## Validation After Each Step

- [x] `SettingsView.swift` diagnosztika
- [x] teljes build
- [x] `CowsAndBullsUITests/testSmokeGameScreen()`
- [x] célzott unit teszt az action orchestration rétegre
  - [x] `GameCoordinatorTests/startNewGameBeginsSession()`
  - [x] `GameCoordinatorTests/resetGameSessionClearsStores()`
- [x] LearnView szekciós bontás build-validációja
- [x] célzott settings UI tesztek
  - [x] `testSettingsProfilesControlsLockDuringActiveGame()`
  - [x] `testSettingsThemeSelectionUpdatesSelectedRow()`
  - [x] `testSettingsProfileReorderButtonsReflectBoundaryState()`
  - [x] `testSettingsProfileReorderInteractionUpdatesOrder()`
  - [x] `testFirstTypingStartsGameInsteadOfLaunch()`
  - [x] `testSettingsLanguageChangeDoesNotRestartWhenChoosingLater()`
- [x] célzott unit teszt a view-ból kiemelt game-screen szabályokra
  - [x] `GamePresentationRulesTests/scoreUsesLowerOfStartedAndCurrentTimerConfigurations()`
  - [x] `GamePresentationRulesTests/timerFlagsAndSurrenderAvailability()`
  - [x] `GamePresentationRulesTests/gameModeMessageAndProfilePickerHelpText()`
  - [x] `GamePresentationRulesTests/profileSelectionDecision()`
  - [x] `GamePresentationRulesTests/pauseAndWindowCloseGuards()`
  - [x] `GamePresentationRulesTests/timeoutSurrenderAndLossMessages()`
  - [x] `GamePresentationRulesTests/lossEndReasonFallback()`

## Important Guardrails

- [x] Ne kerüljön vissza az auto-restart settings változásra.
- [x] A gameplay beállítások maradjanak lockolva futó játék alatt.
- [x] A profilműveletek maradjanak tiltva futó játék alatt.
- [x] Az első gépelés indítsa a játékot, ne a launch vagy profilváltás.
- [ ] Ne kerüljön üzleti logika vissza nagy SwiftUI `body` blokkokba.

## Nice To Have

- [~] Settings UI tesztek a disabled state-ekre
  Már megvan:
  - [x] gameplay settings lock active game alatt
  - [x] profile create lock active game alatt
  - [x] language change restart prompt
  - [x] no auto-restart when choosing restart later
  - [x] first typing starts the game
  - [x] theme selection semantic state update
  - [x] profile reorder boundary-state teszt
  - [x] profile reorder interaction teszt
- [x] külön fájlokba bontani a settings nézeteket, ha még mindig túl nagy a fájl
  Megoldás:
  - [x] `Views/SettingsSupportViews.swift`
  - [x] `Views/SettingsTabViews.swift`
  - [x] `Views/SettingsProfilesViews.swift`
  - [x] `SettingsView.swift` kompozíciós réteggé tisztítva
- [x] LearnView szekciós bontása külön view-kra
  Megoldás:
  - [x] `Views/LearnSection.swift`
  - [x] `Views/LearnContentView.swift`
  - [x] `Views/LearnObjectiveSection.swift`
  - [x] `Views/LearnSkillsSection.swift`
  - [x] `Views/LearnHowToPlaySection.swift`
  - [x] `Views/LearnGuessExplanationSection.swift`
  - [x] `Views/LearnStrategySection.swift`
  - [x] `Views/LearnScoringSection.swift`
  - [x] `Views/LearnOptionsSection.swift`
- [ ] `ProfileEditorState` bevezetése, ha a profiles szerkesztési állapot tovább nő
- [~] A `View` rétegben csak megjelenítés és UI wiring maradjon
  Már megvan:
  - [x] settings tabok fizikai bontása
  - [x] `ProfileEditorState`
  - [x] több ismétlődő döntés helper/property szintre húzva
  - [x] `ContentView` game-screen szabályainak első köre `GamePresentationRules` helperbe húzva
  - [x] `ContentView` game mode / profile picker / profile selection döntések helperbe húzva
  - [x] `ContentView` pause / window-close guardok helperbe húzva
  - [x] `ContentView` timeout / surrender / loss-alert döntések helperbe húzva
  - [x] `ContentView` action orchestration első köre `GameCoordinator`-ba húzva
  - [x] `ContentView` timer task kezelés `GameTimerController`-be húzva
  - [x] `AnimalIconStyle` egyszerűsítve, a felesleges `cornerRadius` paraméter nélkül
  - [x] `ContentView` game tab paraméterezése context adapterekkel rövidítve
  - [x] `ContentView` game tab külön `GameTabView` kompozíciós rétegbe húzva
  - [x] a beágyazott játékképernyő-szekciók külön `GameScreenSections.swift` fájlba mozgatva
  - [x] a timer tick wiring ismétlés `GameTimeLimitCoordinator` helperbe húzva
  - [x] a submit / timeout / surrender orchestration `GameTurnCoordinator` helperbe húzva
  Még hátra van:
  - [ ] a maradék view-oldali döntések további store/helper irányba tolása a következő körökben
