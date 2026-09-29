## Context

Слои 1–2 дают шаблон, копию ученика и страницу занятия. Complete по-прежнему только меняет статус. Прогрессия требует actual vs prescription. Абонементы уже есть на `/session-packages`. Контракт логов — design слоя 1 §7.

## Goals / Non-Goals

**Goals:** лог подходов при complete; progress API; хаб ученика; график по goal.

**Non-Goals:** student-authored logs, auto-increment weights, weekly programs, web.

## Decisions

### 1. Logs at complete, snapshot exerciseId

`session_set_logs`: `id`, `session_id`, `exercise_id` (FK, not only plan_exercise_id — plan rows may later change), `sort_order`, `reps` NULL, `weight_kg` NULL, `duration_seconds` NULL. Unique `(session_id, exercise_id, sort_order)`.

Complete body optional `{ logs: [{ exerciseId, sets: [{ reps?, weightKg?, durationSeconds? }] }] }`. If omitted and `studentPlanId` set → copy current prescription. If omitted and no plan → no log rows (status still completed). If provided, replace any draft (none in v1) and write in the same transaction as status change. Cancel/no_show do not write logs.

Альтернатива: логировать каждый подход во время занятия — отвергнуто (нет live-mode в v1).

### 2. Progress series

`GET /students/:studentId/progress?exerciseId=` — caller is coach of an active link or the student themselves. Points from completed sessions of that pair (if coach) or all completed with that student (if self, still scoped per coach query `coachId` optional). Each point: `{ sessionId, completedAt, weightKg, volume }` where volume = sum(reps * weight) for that exercise that session; weightKg = max working set weight.

Goal on the **assigned copy or last logged session's plan**: hypertrophy chart uses weightKg; fat_loss uses volume; general shows weight if any else volume.

### 3. Student hub UI

`/students/:id` trainer; student uses `/me/training` or same route with self id.

One scroll, four sections (not tabs):

1. Ближайшие — next N booked sessions (time + workout title or «без программы»)
2. Назначенные — assigned copies
3. Абонемент — remaining / create (reuse packages widgets)
4. Прогресс — pick 1–2 exercises (default: most-logged); numbers first→last→delta; simple line chart (mint stroke, Fitness Yoda tokens)

Entry: tap student on session-packages list; Home «Ученики» can keep list but row → hub.

### 4. Complete UX

Session page «Проведена» → if plan attached, bottom sheet or inline steppers prefilled; confirm submits logs+complete. Skip/use as prescribed = send no logs (server copies).

### 5. Chart library

Prefer `fl_chart` only if already a dependency; otherwise CustomPaint / tiny sparkline. Do not add Riverpod. Check pubspec at apply time.

## Risks / Trade-offs

- [Complete without UI confirm writes prescription as actual] → honest default; trainer can open hub and see identical start/now until they start adjusting.
- [Plan edited after complete] → logs keep exerciseId snapshot; charts still work.
- [Empty progress] → hub shows «Проведите занятие с весами, чтобы увидеть график».
- [Multiple coaches] → student self progress grouped by coachId.

## Migration Plan

1. `session_set_logs` table.
2. Extend complete + progress GET.
3. Flutter hub + confirm step + Home links.
4. Rollback: drop table; complete ignores unknown body field.

## Open Questions

Chart package chosen at apply by checking `pubspec.yaml`.
