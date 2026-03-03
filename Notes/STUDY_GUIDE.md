# Cows & Bulls - Study Guide (HU)

Ez a fájl oktatási célú technikai összefoglaló: mit építettünk, miért úgy, és hogyan alkalmazhatod később más projektekben.

## 1. Projekt-architektúra röviden

A jelenlegi felosztás:
- `Views/`: UI réteg (`ContentView`, `HistoryView`, `LearnView`, `SettingsView`, `StatisticView`)
- `Logic/`: tiszta üzleti logika (`GameLogic`, `SoundPlayer`, `Localization`)
- `Models/`: adatmodell és tárolás (`HistoryStore`)
- `Localizable.xcstrings`: string catalog alapú nyelvi kulcsok EN/HU
- `Help/`: HTML alapú help

Miért jó ez?
- A UI és a logika elkülönül, így könnyebb tesztelni és karbantartani.
- A `GameLogic` újrafelhasználható marad (nem kötődik SwiftUI-hoz).

## 2. Állapotkezelés SwiftUI-ban

Sokat használt property wrapperek:
- `@State`: lokális, view-életciklushoz kötött állapot.
- `@AppStorage`: tartós beállítások (`UserDefaults`), pl. nyelv, hangerő, theme.
- `@EnvironmentObject`: globális, megosztott állapot (pl. `HistoryStore`).

### Mikor mit?
- Játék közbeni átmeneti állapot (`guess`, `isGameOver`) -> `@State`
- Beállítások (`enableSoundEffects`, `selectedTheme`) -> `@AppStorage`
- Több nézetben használt közös adat (`historyStore`) -> `@EnvironmentObject`

## 3. Játéklogika kiszervezése (`GameLogic.swift`)

Mit csinál:
- válasz generálás
- bull/cow számolás
- tipp validáció
- pontszám számítás (nehézségi és teljesítmény szorzókkal)

Pontozási modell röviden:
- `baseScore = log10(combinations) * 100`
- `difficulty`: repeats / hard mode / rejtett hátralévő tippszám / tipplimit-nyomás
- `performance`: `min(2.5, standardGuesses / usedGuesses)`
- `timeMultiplier`: 1.0...2.0 tartomány, szigorúbb limit -> nagyobb szorzó
- jackpot: első tippes megoldásnál `+ baseScore * 10.0`

Miért fontos?
- A `ContentView` így vékonyabb, inkább UI-orientált lesz.
- A logika független, így később unit testtel jobban lefedhető.

## 4. Timer-ek (per-guess + game timer)

Megvalósítási minta:
- `Task` alapú számlálók (`Task.sleep` 1 mp ciklussal)
- külön task a tippidőhöz és külön a teljes játékidőhöz
- ha bármelyik aktív limit lejár -> vereség

Kulcspontok:
- timer taskokat mindig cancelálni kell új játék előtt (`stopAllTimers`)
- a UI-állapot változtatása `MainActor`-on történjen

## 5. Hangok és háttérzene

### Sound effects
- rövid eseményhangok: `submit`, `win`, `lose`
- `AVAudioPlayer` cache-elés kulcs alapján
- hangerő `AppStorage`-ból

### Background music
- külön háttérzene-player
- loop (`numberOfLoops = -1`)
- külön beállítások:
  - enable/disable
  - track ID
  - volume

Miért külön a sound és music?
- UX szempontból jobb kontroll: effekt halk lehet, zene külön állítható.

## 6. Lokalizáció (EN/HU)

Stratégia:
- minden user-facing szöveg kulcsra kerül
- `localized("kulcs")` hívások a UI-ban
- `Localizable.xcstrings` string catalog (EN/HU lokalizációkkal)

Nyelvváltás realitás:
- néhány rész csak újraindítás után biztosan frissül teljesen
- ezért került restart prompt a language tabhoz

## 7. Help rendszer: SwiftUI view + HTML help

Két réteg:
- `LearnView`: gyors, appon belüli magyarázat
- `Help/index.html` (EN/HU): klasszikus, kereshetőbb struktúra

Tanulság:
- komplex dokumentációnál HTML help áttekinthetőbb
- in-app LearnView jó onboarding/fallback

## 8. About/Credits lokalizálás

A `showLocalizedAboutPanel()` dinamikusan tölti:
- app nevet
- verzió/build szöveget
- krediteket (`about.credits.body`)

Ez jobb, mint fix `Credits.rtf`, mert:
- teljesen lokalizálható
- egyszerűbben karbantartható strings kulcsokkal

## 8.1 Dokumentáció konzisztencia

Minden scoring/timer változtatás után frissítendő:
- `LearnView` (`learn.*` kulcsok a catalogban)
- HTML Help (`Help/en.lproj/index.html`, `Help/hu.lproj/index.html`)

Ezzel elkerülhető, hogy a UI és a dokumentáció eltérjen a tényleges logikától.

## 9. App név és verziózás

Fontos mezők:
- `MARKETING_VERSION` -> user által látott verzió (pl. `1.8`)
- `CURRENT_PROJECT_VERSION` -> build szám (pl. `2`)
- `CFBundleShortVersionString` és `CFBundleVersion` egyezzen ezekkel

Jelenlegi séma:
- `1.8 (2)`

App név egységesítés:
- `Cows & Bulls` build settings + `Info.plist` szinten is

## 10. Ikonkezelés (Icon Composer)

Kritikus szabály:
- ne legyen névütközés (régi statikus `AppIcon` vs új `.icon` fájl)
- egyértelmű primary icon név legyen beállítva

Tipikus hiba:
- kérdőjel az Xcode-ban = source control/untracked/reference probléma

## 11. UI méretezés és spacing tanulságok

- Ha ablak „túl szélesen” indul, azt jellemzően explicit `.frame(minWidth:, idealWidth:)` okozza.
- Settings taboknál a túl szoros elrendezést `VStack`/`HStack` spacing és `padding` finomhangolással oldottuk.
- Guess sorban a nagyobb font mellé adaptív ikonméret került 8 karakteres esethez.

## 12. Disztribúció App Store nélkül

Jelenlegi praktikus út:
1. Release build
2. `Cows & Bulls.app` + install guide fájlok mappába
3. `ditto`-val ZIP
4. feltöltés webre

Miért `ditto`?
- megbízhatóbban őrzi a macOS app bundle metaadatokat.

## 13. Hasznos saját workflow-javaslat (tanuláshoz)

Minden új feature-nél:
1. Rövid célmondat (mit akarsz)
2. Adatmodell/beállítás döntés (`@State`/`@AppStorage`)
3. UI prototípus
4. Logika kiszervezés (ha nő a komplexitás)
5. Lokalizálás
6. Help/credits frissítés
7. Build + kézi smoke test

## 14. Gyors mini-glosszárium

- **AppStorage**: tartós beállításkulcs `UserDefaults`-ban
- **EnvironmentObject**: shared observable state több view között
- **MainActor**: UI-biztonságos végrehajtási kontextus
- **Build number**: belső növekvő kiadási számláló
- **Marketing version**: felhasználó által látott verzió

## 15. Következő jó tanulófeladatok

1. További unit teszt a `GameLogic`-ra (timer-határok, jackpot, validáció edge case-ek)
2. Külön `AudioManager` protokoll + mock (tesztelhető hangréteg)
3. Settings kulcsok centralizálása egy `SettingsKeys` enumba
4. Egyszerű changelog generálás release előtt

---

Ha szeretnéd, csinálok egy 2. fájlt is `STUDY_GUIDE_EN.md` néven angolul ugyanerről.
