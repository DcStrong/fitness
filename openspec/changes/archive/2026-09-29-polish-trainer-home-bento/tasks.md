## 1. Data layer

- [x] 1.1 Extend `HomeCubit`/`HomeState` to load sessions for the current local calendar week (single `listSessions` week range); keep today upcoming/history grouping via client filter
- [x] 1.2 Add derived counts: today session count, week session count; wire pending count for chips without duplicate banner when chip visible
- [x] 1.3 Unit tests for week range + day grouping helpers

## 2. Week mini-calendar

- [x] 2.1 Add `HomeWeekStrip` widget (7-day row, mint selected/today styling aligned with `CalendarDateStrip`)
- [x] 2.2 Show truncated session hint per day from week payload; empty days without fake labels
- [x] 2.3 Day tap → schedule navigation (preselect date if schedule stack supports it; else `/schedule`)
- [x] 2.4 Widget tests: labels on days with sessions, tap navigation

## 3. Stat chips

- [x] 3.1 Add `HomeStatChips` row: «Сегодня · N», «Заявки · N» (trainer), «На неделе · N»
- [x] 3.2 Tappable chips route to inbox / schedule as designed; hide chip on load failure
- [x] 3.3 Remove redundant large pending banner when chip shows same count

## 4. Asymmetric bento (trainer)

- [x] 4.1 Add `HomeBentoShortcuts`: tall «Расписание», stacked «Ученики» + «Планирование», full-width «Регулярные»
- [x] 4.2 Finance tile when `finance:read_own`; reuse existing routes/keys from `_featureCards`
- [x] 4.3 Replace `_FeatureCardGrid` for trainer with bento; keep gradient/icon language or simplify to hub-style action cells (`actionFill`)
- [x] 4.4 Widget tests: bento renders 4 core tiles; finance conditional

## 5. Student Home

- [x] 5.1 Force 2-column `_FeatureCardGrid` on phone widths
- [x] 5.2 Optional lighter week strip for student (upcoming hints only) — skip if scope tight

## 6. Verify

- [x] 6.1 `dart analyze` clean on touched files
- [x] 6.2 Update/add `home_view` / widget tests; run focused test suite
- [x] 6.3 Manual smoke: week strip labels match API; bento routes; chips; student 2-col; compare to `mock-home-c-asymmetric-bento.png`
