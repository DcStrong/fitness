## 1. Scale and placement

- [x] 1.1 In `calendar_day_timeline.dart`, compute day-wide `pxPerMinute = max(base, max over events of minCardHeight/durationMinutes)` and `hourHeight = 60 * pxPerMinute` (cap if needed for short events)
- [x] 1.2 Rewrite `_offsetFor` / `_heightFor` / empty-hour `Positioned` / label `SizedBox` to use the day scale instead of fixed `_hourHeight`
- [x] 1.3 Keep working-hours ∪ out-of-band hour list and overlap stacking behavior unchanged

## 2. Tests

- [x] 2.1 Add/extend `@visibleForTesting` helpers for scale / tops / heights as needed
- [x] 2.2 Cover mid-hour 12:10–13:10 placement vs hour-aligned 12:00–13:00 baseline (no unnecessary zoom)
- [x] 2.3 Cover empty working hour still present on the scaled grid

## 3. Optional half-hour labels

- [x] 3.1 (Optional) Show muted `HH:30` on hours that have an event start/end at minute 30; skip if layout is crowded after smoke

## 4. Verify

- [x] 4.1 Run focused Flutter tests for day timeline / calendar views
- [x] 4.2 Manual smoke: 12:10–13:10, whole-hour booking, empty working hours, late out-of-band 23:00
