## 1. Session page hierarchy

- [x] 1.1 Replace lifecycle `FilledButton`/`OutlinedButton` on `/sessions/:id` with `FyButton.primary` «Проведена» as the only filled CTA; keep `session-complete` key
- [x] 1.2 Move неявка / отмена / история into AppBar ⋯ (or a single quiet text row if the menu would have one item); keep `session-no-show`, `session-cancel`, `session-history` keys on the menu items
- [x] 1.3 Change состав / смена / добавить / убрать / упражнения из списка / программа серии from stadium secondary buttons to text links; keep existing keys
- [x] 1.4 Empty plan: one primary «Выбрать тренировку»; confirm-sets sheet before complete unchanged
- [x] 1.5 Update session widget/cubit tests if they find buttons by type

## 2. Student hub layout

- [x] 2.1 Person header: initials, name, package line, tappable next session → `/sessions/:id`
- [x] 2.2 «На этой неделе» from this-week booked sessions and/or GET program when `recurringBookingId` exists; «Программа» text link to existing program route
- [x] 2.3 Trainer-only 2×2 grid: Записать, Назначить, Абонемент, Программа (cards, not primary buttons) wired to book-for-student, assign sheet, `/session-packages`, program/series
- [x] 2.4 Workouts section with «Назначить» text action; keep progress block; hide coach grid on student self hub
- [x] 2.5 Update hub widget tests for header/grid vs old stacked CTA cards

## 3. Library compact tags + search sheet

- [x] 3.1 Rank own tags by usage on loaded templates/exercises; show up to four chips plus «Ещё» when more exist; keep selected tag visible in the row
- [x] 3.2 Tag search bottom sheet: query, list, selected chips, apply; filters library; no difficulty/equipment/muscles
- [x] 3.3 Cover ranking + sheet apply in cubit/widget tests

## 4. Tags as groups

- [x] 4.1 `/tags` cards: name + composition summary + chevron; remove per-row trash; keep `tag-row-*` and create-from-search
- [x] 4.2 Load hub summaries in parallel for visible tags (cap ~15); degrade to name-only on error
- [x] 4.3 Delete tag from tag hub overflow, not the list row
- [x] 4.4 Update tags tests that tapped delete on the list

## 5. Verification

- [x] 5.1 `dart analyze` on touched Flutter files
- [x] 5.2 Focused Flutter tests for session CTA, hub grid, compact tags, tags list without trash
- [x] 5.3 Manual smoke vs local API: hub A+B, session one CTA, library Ещё sheet, tags cards → hub, no extra mock chrome

## 6. Visual polish vs mocks

- [x] 6.1 Circular dark-green FAB (`CircleBorder` + `primaryContainer` override; explicit colors on library FAB)
- [x] 6.2 Selected chips as filled primary pills (`FyChip`); library unselected outlined; segmented «Мои» without checkmark
- [x] 6.3 Student hub: name from relationship/extra, mint initials, package pill, tall 2×2 softFill cells, circular workout thumbs, one progress card
- [x] 6.4 Session: empty state has no «Проведена» text link; complete only as primary when workout exists (overflow otherwise)
- [x] 6.5 Library compact outlined/filled `FyChip` row + circular mint plan thumb; pill search
- [x] 6.6 Tags list: icon tile, circular count badge, light circled + create row, pill search
