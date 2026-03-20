# Refactoring Checklist

## Immediate Next Steps

- [ ] Szedd ki a visszatérő szabálylogikát computed property-kbe a `SettingsView`-ban.
- [ ] Adj stabil accessibility identifier-eket a fontos settings vezérlőknek.
- [ ] Vezesd be a közös kis UI elemeket:
  - [ ] `SettingsHelpCaption`
  - [ ] `SettingsSliderRow`
  - [ ] `SettingsSectionTitle`
  - [ ] `SettingsLockedNotice`
- [ ] Tisztítsd a profiles helper logikát, ha még túl zajos.
- [ ] Döntsd el, hogy az `animalThemes` maradjon-e helyben vagy menjen külön fájlba.

## Validation After Each Step

- [ ] `SettingsView.swift` diagnosztika
- [ ] teljes build
- [ ] `CowsAndBullsUITests/testSmokeGameScreen()`

## Important Guardrails

- [ ] Ne kerüljön vissza az auto-restart settings változásra.
- [ ] A gameplay beállítások maradjanak lockolva futó játék alatt.
- [ ] A profilműveletek maradjanak tiltva futó játék alatt.
- [ ] Az első gépelés indítsa a játékot, ne a launch vagy profilváltás.
- [ ] Ne kerüljön üzleti logika vissza nagy SwiftUI `body` blokkokba.

## Nice To Have

- [ ] Settings UI tesztek a disabled state-ekre
- [ ] külön fájlokba bontani a settings nézeteket, ha még mindig túl nagy a fájl
- [ ] `ProfileEditorState` bevezetése, ha a profiles szerkesztési állapot tovább nő
