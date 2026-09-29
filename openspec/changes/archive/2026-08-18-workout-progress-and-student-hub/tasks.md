## 1. Logs persistence and complete

- [x] 1.1 Entity `SessionSetLog` + migration + unique `(session_id, exercise_id, sort_order)`
- [x] 1.2 Domain types for log payload and progress points under `src/sessions/interface/` or `src/progress/interface/`
- [x] 1.3 Extend complete to accept optional `logs`; same transaction as status; omit → copy prescription if plan attached
- [x] 1.4 Cancel / no_show write no logs; completed logs immutable
- [x] 1.5 Unit tests: explicit logs, copy prescription, no plan, cancel has zero logs, non-coach 403

## 2. Progress API

- [x] 2.1 `GET /students/:id/progress?exerciseId=` for linked coach or self; 403 otherwise
- [x] 2.2 Points: completedAt, max weightKg, volume sum(reps*weight); ordered by time
- [x] 2.3 Unit + e2e: two completed sessions → two points; outsider 403

## 3. Session page confirm step

- [x] 3.1 Before «Проведена», if plan attached, show prefilled sets; allow edit; submit logs
- [x] 3.2 Confirm-as-prescribed omits logs or sends equals; no plan skips editor
- [x] 3.3 Widget/Cubit tests for confirm and adjust-weight path

## 4. Student hub

- [x] 4.1 Route `/students/:id` (trainer) and student self hub; Cubit aggregating sessions, assigned plans, package, progress
- [x] 4.2 Four stacked sections: upcoming, assigned copies, package, progress (no extra tab bar)
- [x] 4.3 Session-packages list row navigates to hub; upcoming row opens session page
- [x] 4.4 Student hub is read-only except existing cancel/package view rules

## 5. Charts and Home

- [x] 5.1 Progress numbers first/current/delta; line chart using Fitness Yoda tokens; goal selects weight vs volume
- [x] 5.2 Empty progress copy in Russian
- [x] 5.3 Home session row shows workout title when attached and opens session page
- [x] 5.4 Student Home «Тренировки»/«Планы» card opens assigned + upcoming, not body-only visible plans

## 6. Verification

- [x] 6.1 Focused Nest tests for complete logs + progress
- [x] 6.2 Focused Flutter tests for hub sections and chart empty/data
- [x] 6.3 Manual smoke: assign hypertrophy workout, complete twice with increasing weight, hub chart rises; fat_loss copy shows volume
