# Cows & Bulls - Release Build útmutató

Ez az útmutató a jelenlegi, App Store-on kívüli (ZIP-es) kiadási folyamathoz készült.

## 1. Verziózás

A kiadás előtt ellenőrizd / növeld:
- `MARKETING_VERSION` (pl. `1.8` -> `1.9`)
- `CURRENT_PROJECT_VERSION` (build szám, pl. `2` -> `3`)

Jelenleg:
- Verzió: `1.8`
- Build: `2`

## 2. Release build Xcode-ban

1. Nyisd meg a projektet Xcode-ban.
2. Scheme: `CowsAndBulls`.
3. Build configuration: `Release`.
4. `Product > Clean Build Folder`.
5. `Product > Build`.

## 3. Kiadási csomag mappa létrehozása

Javasolt mappanév formátum:
- `CowsAndBulls-<verzió>.<build>`
- példa: `CowsAndBulls-1.8.2`

A mappába tedd bele:
- `Cows & Bulls.app`
- `INSTALL.en.md`
- `INSTALL.hu.md`

## 4. ZIP készítése (ajánlott parancs)

A projekt gyökeréből futtasd:

```bash
ditto -c -k --sequesterRsrc --keepParent "CowsAndBulls-1.8.2" "CowsAndBulls-1.8.2.zip"
```

Ez megőrzi az `.app` csomag metaadatait megbízhatóbban, mint egy sima ZIP.

## 5. Gyors ellenőrzés feltöltés előtt

1. Töröld a helyi, korábban telepített appot.
2. Csomagold ki a ZIP-et egy tesztmappába.
3. Indítsd el az appot a ZIP-ből kibontott példányból.
4. Ellenőrizd:
   - ikon
   - nyelvváltás
   - hang/zene
   - alap játékmenet

## 6. Publikálás a honlapra

A feltöltendő fájl:
- `CowsAndBulls-1.8.2.zip`

Ajánlott mellé rövid szöveg:
- macOS verzió
- kiadási dátum
- rövid changelog
- telepítési lépésekre hivatkozás (`INSTALL.en.md`, `INSTALL.hu.md`)

## 7. Megjegyzés (jelenlegi állapot)

Mivel nincs Developer ID aláírás + notarization:
- első indításkor Gatekeeper figyelmeztetés várható.
- ezt az `INSTALL` fájlok kezelik (`Right click -> Open`, illetve `Open Anyway`).

---

## Opcionális jövőbeli bővítés

Ha később lesz Apple Developer előfizetés:
1. Developer ID aláírás
2. Notarization (`notarytool`)
3. ugyanilyen ZIP/DMG terjesztés, de kevesebb felhasználói figyelmeztetéssel
