## 1. Theme and font

- [x] 1.1 Add `google_fonts` (or bundled Plus Jakarta Sans assets) to `app/fitness_app/pubspec.yaml`
- [x] 1.2 Wire Plus Jakarta Sans into `AppTheme.light()` text theme; leave dark stub untouched (wave C)
- [x] 1.3 Update `docs/design/design-system-status.md` font row comment if needed after apply smoke

## 2. Shared primitives

- [x] 2.1 Implement `FySecondaryButton` (outlined stadium, loading, disabled) under `lib/core/widgets/`
- [x] 2.2 Implement `FyChip` (selected/unselected, Fitness Yoda colors)
- [x] 2.3 Implement `showFyBottomSheet` helper with documented surface/radius/safe area
- [x] 2.4 Add barrel export `lib/core/widgets/widgets.dart` (or equivalent) for shared primitives

## 3. Calendar / schedule consumers

- [x] 3.1 Migrate `calendar_event_card.dart` from raw `Card` to `FyCard`
- [x] 3.2 Route `ScheduleCreateActionsSheet`, `OpenSlotActionsSheet`, `FreeTimeSheet` through `showFyBottomSheet`
- [x] 3.3 Migrate weekday/mode/type chips used in schedule flows to `FyChip`

## 4. Recurring consumers

- [x] 4.1 Replace raw `OutlinedButton` on `recurring_booking_detail_page.dart` with `FySecondaryButton`
- [x] 4.2 Migrate recurring create weekday/mode chips to `FyChip` where still local

## 5. Verification

- [x] 5.1 Widget tests for `FySecondaryButton` / `FyChip` / sheet helper smoke (or extend existing schedule UX tests)
- [x] 5.2 `dart format`, `flutter analyze` clean for touched paths
- [x] 5.3 Manual smoke (macOS or Chrome): Login typography; FAB create sheet; open-slot sheet; recurring detail secondary; weekday chips
- [x] 5.4 Ready for `/opsx-archive` after apply (waves B/C remain separate proposes)
