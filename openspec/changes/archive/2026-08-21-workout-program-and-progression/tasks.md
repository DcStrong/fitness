## 1. Persistence

- [x] 1.1 Migration: `workout_programs` (unique `recurring_booking_id`), `workout_program_days` (weekday 1–7), `workout_program_day_items` (template + student_copy + sort), `workout_progression_rules` (`exercise_id`, start/delta/increment, hold)
- [x] 1.2 Migration: `session_workout_items` (session, sort, student_plan_id, source program|manual, override_at) and `session_prescription_sets` (item, exercise, order, reps, weight, duration)
- [x] 1.3 Backfill: existing `sessions.student_plan_id` → one manual item + snapshot from current plan sets; keep `student_plan_id` in sync with first item
- [x] 1.4 Domain types under `src/workout-programs/interface/` and session workout/snapshot types (no types in entity files)

## 2. Plan loads and session multi-attach

- [x] 2.1 `PATCH /plans/:id/loads` owner-only; apply weightKg to all sets of listed `weight_reps` exercises; reject catalog/foreign/unknown ids
- [x] 2.2 GET session includes `workouts[]` and `studentPlanId` alias of first; PATCH `workoutPlanIds` or single `studentPlanId`; empty/null detaches; student 403; mark override on manual PATCH
- [x] 2.3 Complete without logs copies **snapshot** sets (not live copy) when snapshots exist
- [x] 2.4 Unit tests: loads isolation template vs copy; two workouts; wrong student 400; complete uses snapshot after copy edited

## 3. Programs API

- [x] 3.1 `GET/PUT /recurring-bookings/:id/program` and `POST .../program/apply`; PUT transactional; weekdays ⊆ series; idempotent assign copies; horizon 1–8 default 2; cancelled series 400
- [x] 3.2 Interpolation service: occurrences of each progressed exercise in horizon; first = start, last = start+delta; round to increment; write snapshots; skip completed/overridden unless force
- [x] 3.3 Recurring sync calls apply on newly booked sessions
- [x] 3.4 Complete hook: on-plan vs miss; hold missed lift; roll horizon when on-plan and <1 week remains; update copy start on roll
- [x] 3.5 Unit + e2e: Mon/Sat strength + Thu legs; +5 kg / 2 weeks last point 85; weekday not in series 400; override skipped; miss holds bench only; idempotent re-PUT

## 4. Flutter program screen

- [x] 4.1 Feature `workout_program`: Dio API, repository, Cubit, route `/recurring/:id/program`
- [x] 4.2 One-scroll Russian UI: horizon, weekday sections, add templates, loads table per card, progression rows, date preview, save = PUT
- [x] 4.3 Validation: empty weekday blocked; Bloc/Cubit only
- [x] 4.4 Entries: series detail «Программа»; calendar booked event of series; student hub/profile when series exists
- [x] 4.5 Widget/Cubit tests: two weekdays + delta save; empty day blocked

## 5. Flutter templates, session, calendar

- [x] 5.1 Template/copy editor: section «Нагрузки» (weight_reps only); persist via loads PATCH; library exercise form has no per-student kg
- [x] 5.2 Session page: stacked workouts from GET; add/remove one of many; edit snapshot weight sets override; student read-only
- [x] 5.3 Calendar event shows up to two workout titles; session tap still `/sessions/:id`
- [x] 5.4 Widget tests: two workouts on session; calendar subtitle; loads table omits bodyweight

## 6. Docs and verification

- [x] 6.1 Update `docs/domain/entities.md` (and tags/plans docs if they still say one plan per session): Exercise vs template vs copy vs program vs session snapshot
- [x] 6.2 Focused Nest tests for program apply, hold/roll, session workouts
- [x] 6.3 Focused Flutter tests for program screen and session multi-workout
- [x] 6.4 Manual smoke: series ПН/ЧТ/СБ; силовая ПН+СБ, ноги ЧТ; жим +5 кг / 2 недели; календарь показывает названия; complete по плану не требует правок следующих слотов; промах по жиму держит жим; правка кг на одной сессии не затирается apply
