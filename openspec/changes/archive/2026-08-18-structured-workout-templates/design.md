## Context

`TrainingPlan` сегодня — `title` + `body` text, видимость через теги ([docs/domain/tags.md](../../docs/domain/tags.md)). Конструктор упражнений в 2026-07-18 сознательно отложили. Session не знает содержимое занятия.

Индустрия (Hevy routine vs log, CoachingPortal assign-as-copy, OpenWeight prescription) разделяет **шаблон → копия ученика → лог факта**. Референсное приложение перегружает тремя вкладками, полом, сложностью и аккордеоном подходов — это антипаттерн для Fitness Yoda.

Стек: NestJS + TypeORM, Flutter Bloc/Cubit, Russian UI, токены [AppColors](../../app/fitness_app/lib/app/theme/app_colors.dart). Web вне скоупа.

Этот change реализует **слой 1 (библиотека шаблонов)**. Слои 2–3 описаны здесь как контракт, чтобы следующие change не перепроектировали схему.

## Goals / Non-Goals

**Goals:**

- Exercise library тренера + неизменяемый seed-каталог.
- Шаблон с `goal`, тегами, nested exercises/sets.
- Flutter: «Мои | База», компактные карточки, одноэкранный редактор.
- Сохранить теги как группировку людей и ярлык на плане.
- Зафиксировать целевые сущности слоёв 2–3 (`student_copy`, assignment, `session.studentPlanId`, set log, progress).

**Non-Goals (код этого change):**

- Assign/copy ученику, страница `/sessions/:id`, логи, графики, `/students/:id`.
- Программы на недели, суперсеты, RPE/1RM/tempo, пол/сложность как поля, web.

## Decisions

### 1. Три слоя (целевая модель продукта)

```
TrainingPlan kind=template|catalog_seed
  → (фаза 2) copy-on-assign → kind=student_copy
  → Session.studentPlanId
  → (фаза 3) SessionSetLog → progress series
```

Не плодим отдельный HTTP-домен «workouts»: расширяем `plans` + тонкий `exercises`. Теги не меняют семантику.

Альтернатива: JSON `items[]` в колонке плана — отвергнуто: нельзя нормально индексировать exerciseId для прогрессии.

### 2. Схема слоя 1 (этот change)

**`exercises`**

- `id`, `name` (varchar 120), `kind` (`weight_reps` | `bodyweight_reps` | `duration`)
- `owner_coach_id` uuid NULL — NULL = catalog seed
- unique `(owner_coach_id, lower(name))` через unique index; для catalog `WHERE owner_coach_id IS NULL`

**`training_plans` (additive)**

- `kind` varchar: `template` | `catalog_seed` | `student_copy` (последний не используется до фазы 2, но CHECK сразу включает значение)
- `goal` varchar: `hypertrophy` | `fat_loss` | `general`, default `general`
- `body` остаётся, в API отдаём как `notes` и принимаем `notes` (alias `body` на вход для совместимости)
- `parent_template_id` uuid NULL, `assigned_student_id` uuid NULL — колонки **сразу**, чтобы фаза 2 не переписывала таблицу. В этом change всегда NULL; write API их игнорирует.

**`plan_exercises`**: `plan_id`, `exercise_id`, `sort_order`, `rest_seconds` NULL, `notes` text default ''

**`plan_sets`**: `plan_exercise_id`, `sort_order`, `reps` int NULL, `weight_kg` numeric(6,2) NULL, `duration_seconds` int NULL

Существующие планы: `kind=template`, `goal=general`, 0 упражнений — валидны.

### 3. Goal — дискриминатор, не два домена

Одно поле. UI — три пилюли. Дефолты при добавлении упражнения:

| goal | sets×reps | rest |
|------|-----------|------|
| hypertrophy | 3×10 | 90s |
| fat_loss | 3×15 | 45s |
| general | 3×12 | 60s |

Источник истины — `goal`, не тег. Чип «Набор» / «Похудение» / «Общее» в UI. Теги по-прежнему свободные (#Ноги, #Спина).

Альтернатива: отдельные таблицы fat_loss_plans / hypertrophy_plans — отвергнуто как сложность референса.

### 4. Каталог vs мои

- Seed: ~10 шаблонов `kind=catalog_seed` + набор catalog exercises (русские имена: «Тяга верхнего блока», «Приседания со штангой», …). Без гендерных форков.
- `GET /plans?kind=catalog` — все `catalog_seed`.
- `GET /plans` (own) — только `kind=template` текущего тренера (не копии учеников, не каталог).
- `POST /plans/:id/clone` — catalog → новый `template` владельца: копия метаданных, exercises/sets; **те же `exercise_id`**, если exercise catalog; теги не копируются (у seed их нет).
- Мутация catalog запрещена всем, кроме seed-миграции.

Альтернатива: смешать каталог и «мои» в одном list — отвергнуто (как в референсе).

### 5. API слоя 1

**Exercises**

- `GET /exercises` — own + catalog (`source: own|catalog`)
- `POST /exercises` `{ name, kind }` — own
- `PATCH /exercises/:id` / `DELETE /exercises/:id` — own only; delete 409 если referenced в `plan_exercises`

**Plans** (расширение)

- `POST /plans` `{ title, goal?, notes?, tagIds?, exercises: [{ exerciseId, restSeconds?, notes?, sets: [{ reps?, weightKg?, durationSeconds? }] }] }` → `kind=template`
- `PATCH /plans/:id` — replace exercises list when `exercises` sent; запрет если `kind=catalog_seed`; запрет чужого
- `GET /plans?kind=template|catalog` (default template for trainer)
- `GET /plans/:id` — owner, или visible student (как сейчас, только `template`/`catalog_seed` с тегами), или catalog
- `POST /plans/:id/clone` — из catalog в own template
- `DELETE /plans/:id` — own template only; cascade exercises/sets rows

Permissions: `exercises:manage_own` trainer; `exercises:read_own` trainer+student (студент читает catalog/имена для visible планов). Либо student читает упражнения только через nested plan payload — предпочтительно **вложить exercises в plan response**, отдельный list exercises студенту не нужен на фазе 1.

Student `GET /plans/visible` остаётся: tagged templates linked coach. Catalog студенту в этом change не показываем.

### 6. Flutter слоя 1

Feature остаётся `features/plans` (+ models exercises). Cubit: `PlansLibraryCubit` (list Мои/База, filter tags), `PlanEditorCubit`.

- Список: сегмент Мои | База, поиск по title, горизонтальные чипы своих тегов, карточка: title, goal chip, 1–2 тега, «N упражнений».
- FAB только на «Мои» → `/plans/edit`.
- База: кнопка «Добавить к себе» на карточке/детали → clone.
- Редактор один экран: название*, цель (3 пилюли), теги, заметка, список упражнений. Строка упражнения: имя, `3×12 · 20 кг · отдых 90с` — **не** раскрывать каждый подход. Tap → sheet правки: число подходов (одинаковые reps/weight), reps, weight, rest. Kind duration: секунды вместо reps/weight.
- Добавить упражнение: search own+catalog, или создать имя+kind.
- Деталь: компактный состав; для own — edit + (фаза 2) assign placeholder не делать.

Без Riverpod/freezed/get_it. Не копировать тёмную тему референса.

### 7. Слои 2–3 (контракт, без кода здесь)

**Фаза 2 `workout-assign-and-session-page`**

- `POST /plans/:id/assign` `{ studentIds?, tagIds? }` — только `kind=template`. На каждого ученика: если копия этого шаблона уже есть — вернуть её; иначе insert `kind=student_copy` с `parent_template_id`, `assigned_student_id`, deep copy exercises/sets, теги можно скопировать. Шаблон не мутируется.
- Правка `student_copy` не трогает parent и другие копии.
- `GET /plans?kind=assigned&studentId=` — копии ученика (trainer пары или сам студент).
- `sessions.student_plan_id` uuid NULL FK → training_plans.
- `PATCH /sessions/:id` `{ studentPlanId }` — coach; план должен быть copy этого student (или clone-on-attach из template).
- Flutter: «Назначить» sheet (ученики ∪ теги). Тап booked session → `/sessions/:id` (не `SessionActionsSheet`): время, ученик, теги/цель, состав, CTA «Выбрать тренировку», действия Проведена/Отменить/Неявка. Sheet только для free slots.

**Фаза 3 `workout-progress-and-student-hub`**

- `session_set_logs`: `session_id`, `plan_exercise_id` (или snapshot `exercise_id` + order), `sort_order`, `reps`, `weight_kg`, `duration_seconds`. Пишется в `POST /sessions/:id/complete` optional `logs`; если logs нет — скопировать prescription.
- Логирует тренер; студент read-only.
- `GET /students/:id/progress?exerciseId=` → `{ date, weightKg, volume }` из completed sessions. Chart: hypertrophy = вес; fat_loss = volume (`sets*reps*weight`).
- Flutter `/students/:id`: ближайшие занятия, назначенные копии, абонемент, прогресс (цифры старт→сейчас + линейный график). Ученик: Home «Тренировки» = предстоящие + assigned copies.

### 8. Модули и типы

- Nest: `exercises` module; `plans` расширяется. Domain types в `src/exercises/interface/`, `src/plans/interface/`.
- Seed catalog: SQL в migration **или** `seed.ts` идемпотентный upsert по стабильным UUID — предпочесть migration+seed.ts upsert, чтобы dev/prod совпадали.
- Repository: persist only (project skill).

## Risks / Trade-offs

- [Старые title+body планы без упражнений] → список показывает «0 упражнений»; редактор позволяет добрать. `notes` сохраняет body.
- [Clone каталога расходится с обновлением seed] → принято: копии независимы, как будущий assign.
- [Одинаковые подходы на упражнение] → UI задаёт N одинаковых set rows. Разные веса по подходам — правка числа подходов + позже (не v1 editor complexity). API уже хранит per-set, так что фаза 3 лог может отличаться.
- [student_copy колонки пустые до фазы 2] → CHECK kind допускает значение; API слоя 1 отвергает create с assignedStudentId.
- [Студент видит tagged template без копии] → `GET /plans/visible` сохраняем; «мои тренировки» появятся в фазе 2.

## Migration Plan

1. Migration: exercises, plan_exercises, plan_sets, columns on training_plans, indexes, FKs.
2. Seed permissions `exercises:manage_own`, `exercises:read_own`.
3. Seed catalog exercises + templates.
4. Deploy API then Flutter (Flutter без API сломает editor — выпускать вместе).
5. Rollback: drop new tables/columns; `body` не трогаем.

## Open Questions

Нет блокирующих. Имена 10 seed-шаблонов фиксируются в tasks (верх/низ/фулбоди × hypertrophy/fat_loss + 2 general).
