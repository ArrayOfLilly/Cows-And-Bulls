# Cows & Bulls 1.9.2

Release date: 2026-03-03

## Downloads
- Download (DMG): https://github.com/ArrayOfLilly/Cows-And-Bulls/releases/download/v1.9.2/CowsAndBulls-1.9.2.dmg
- Install guide (EN): https://github.com/ArrayOfLilly/Cows-And-Bulls/blob/main/INSTALL.en.md
- Install guide (HU): https://github.com/ArrayOfLilly/Cows-And-Bulls/blob/main/INSTALL.hu.md

## Highlights
- Added timed-game quality-of-life controls:
  pause/resume support during timed matches and a surrender action.
- Improved input validation UX:
  multiple validation messages can appear together, and they update live while typing.
- Improved scoring fairness:
  if timer settings change mid-game, scoring now uses the lower-scoring configuration.
- Refined game flow:
  zero-step timeout sessions are no longer saved to history.
- UI polish:
  `Give up` action moved next to `Restart`, with updated orange-red accent.

## Statistics & Data
- Added/verified longest win streak metric in statistics.
- Timing-related statistics now use timed matches only.
- Improved history persistence test coverage.

## Localization & Content
- Continued migration and cleanup around localization usage (`.xcstrings`).
- Fixed missing and inconsistent localized strings.
- Updated in-app wording (including "answer" terminology in Hungarian context as needed).

## Stability
- Build validated after changes.
- Test suite passing.
