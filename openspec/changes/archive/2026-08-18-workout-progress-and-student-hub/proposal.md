## Why

Без факта подходов шаблон и календарь не показывают, с какого веса ученик начал и куда дошёл. Тренеру нужна карточка ученика: ближайшие занятия, назначенные тренировки, абонемент и прогрессия цифрами плюс простым графиком. Цель (`hypertrophy` / `fat_loss`) уже есть на плане — она выбирает метрику графика, не отдельную сущность.

## What Changes

- При `POST /sessions/:id/complete` тренер MAY передать actual set logs; если logs нет и план привязан — скопировать prescription. Логи иммутабельны после complete.
- Таблица `session_set_logs` (session, exercise, order, reps, weightKg, durationSeconds).
- `GET /students/:id/progress?exerciseId=` — серия `{ date, weightKg, volume }` из completed sessions пары coach–student.
- Flutter: на странице занятия перед «Проведена» сверка весов (префил из плана). `/students/:id` — один скролл: ближайшие, назначенные копии, абонемент, прогресс (старт → сейчас → дельта + линейный график). Ученик видит свой хаб и read-only логи.
- Home: строка занятия ведёт на session page; карточка ученика «Тренировки»/«Планы» показывает предстоящие + assigned copies.

## Non-goals

- Лог от ученика; RPE/1RM; автопрогрессия весов; программы на недели; web; push.
- Сплит доменов похудение/набор (только `goal` → метрика).
- Пересчёт логов при правке копии после complete.

## Capabilities

### New Capabilities

- `workout-progress-api`: set logs on complete; progress series per student+exercise.
- `mobile-student-hub`: Flutter `/students/:id` (schedule, assigned workouts, package, progress).
- `mobile-workout-progress`: numbers + line chart; goal selects weight vs volume.

### Modified Capabilities

- `session-lifecycle`: complete accepts optional logs; default copy prescription.
- `mobile-session-workout`: confirm-weights step before complete.
- `mobile-home-dashboard`: session row opens workout page; student cards include assigned/upcoming workouts.
- `mobile-session-packages`: student row opens the hub.

## Impact

- Backend: `session_set_logs` migration; complete payload; progress endpoint; permissions reuse sessions/plans/packages.
- Flutter: chart (keep dependency light — e.g. existing CustomPaint or a small chart widget already in ecosystem; no Riverpod).
- Depends on `workout-assign-and-session-page`.
