# Cows & Bulls 1.9.2

Kiadás dátuma: 2026-03-03

## Főbb újdonságok
- Időzített játékoknál kényelmi funkciók:
  bekerült a szüneteltetés/folytatás, illetve a feladás lehetősége.
- Jobb input validációs UX:
  egyszerre több hibaüzenet is megjelenhet, és gépelés közben azonnal frissülnek.
- Igazságosabb pontozás:
  ha játék közben módosulnak az időzítős beállítások, a rendszer az alacsonyabb pontot adó verzióval számol.
- Finomított játékfolyamat:
  a 0 lépéses timeout körök nem kerülnek mentésre a history-ba.
- UI finomhangolás:
  a `Give up` gomb a `Restart` mellé került, frissített narancs-vörös színnel.

## Statisztika és adatok
- Bekerült/ellenőrizve lett a leghosszabb győzelmi sorozat (win streak) statisztika.
- Az időtartamra vonatkozó statisztikák mostantól csak az időzített meccseket veszik figyelembe.
- Erősített history perzisztencia tesztlefedettség.

## Lokalizáció és tartalom
- Folytatódott a lokalizáció tisztítása és egységesítése (`.xcstrings`).
- Hiányzó és inkonzisztens fordítások javítása.
- Szövegezési pontosítások (pl. magyar környezetben a "kitalálandó sorozat" fogalom).

## Stabilitás
- Build ellenőrizve a módosítások után.
- A tesztcsomag zöld.

