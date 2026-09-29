## Why

Тренерские «планы» сейчас — `title` + текстовый `body`. Нельзя задать упражнения, подходы, вес, отдых и цель (набор / похудение / общее), а референсные фитнес-приложения перегружают экран тремя вкладками, полом, сложностью и аккордеоном подходов. Нужен простой конструктор шаблона поверх существующих тегов: библиотека «мои / база», карточка `3×12 · 20 кг`, без wizard.

## What Changes

- Добавить домен **Exercise** (библиотека тренера + seed-каталог): `name`, `kind` (`weight_reps` | `bodyweight_reps` | `duration`).
- Расширить **TrainingPlan**: `kind` (`template` | `catalog_seed` на этой фазе), `goal` (`hypertrophy` | `fat_loss` | `general`), `notes` (= бывший `body`).
- Структурированное содержимое: `plan_exercises` + `plan_sets` (порядок, повторы, вес кг, отдых на упражнение).
- Seed 8–12 русскоязычных шаблонов «База» (верх / низ / фулбоди × цель). «Добавить к себе» копирует seed в `kind=template` тренера.
- API: CRUD упражнений; create/update плана принимает nested exercises/sets; list own отличает шаблоны тренера от каталога.
- Flutter `/plans`: сегмент «Мои | База», поиск + чипы тегов, компактные карточки, редактор на одном экране (имя, цель, теги, заметка, упражнения) без wizard и без аккордеона одинаковых подходов.
- Теги: без смены правил владения/видимости (`UserTag` ∩ `TrainingPlanTag`).
- **Не breaking** для существующих планов: `body` остаётся как `notes`; пустой список упражнений допустим у старых записей.

## Non-goals

- Copy-on-assign ученику, `WorkoutAssignment`, `session.studentPlanId`, страница занятия вместо `SessionActionsSheet` — change `workout-assign-and-session-page`.
- Логи подходов при complete, графики прогрессии, `/students/:id` — change `workout-progress-and-student-hub`.
- Программы на недели, суперсеты, RPE / 1RM / tempo / dropset / дистанция.
- Поля «пол» и «уровень сложности» (это теги, если тренеру нужно).
- Лог от ученика; автопрокидывание правок шаблона в копии; web; push.

## Capabilities

### New Capabilities

- `exercises-api`: HTTP API библиотеки упражнений тренера и чтения seed-каталога; create/list/update/delete own; запрет мутации seed.
- `mobile-workout-templates`: Flutter UI библиотеки шаблонов (Мои / База), компактные карточки, одноэкранный редактор упражнений/подходов с тегами и целью.

### Modified Capabilities

- `plans-api`: план шаблона несёт `kind`, `goal`, `notes` и nested exercises/sets; list own не смешивает каталог с шаблонами тренера без явного фильтра.
- `mobile-plans-tags`: список и редактор планов больше не ограничиваются title+body; деталь показывает компактный состав `N×reps`.
- `access-control`: permission `exercises:manage_own` (trainer); чтение каталога через `plans:read_own` / `exercises:read_own` по design.
- `mobile-app-shell`: маршруты редактора/каталога остаются под `/plans` (без новой ветки shell).

## Impact

- Backend `backend/api`: entities + migration (`exercises`, `plan_exercises`, `plan_sets`, колонки на `training_plans`); модуль `exercises`; расширение `plans` DTO/service; permissions seed; unit + e2e.
- Flutter `app/fitness_app/lib/features/plans`: модели, repository, Cubit, экраны списка/редактора/детали; Bloc only; Russian copy; токены Fitness Yoda (не тёмная тема референса).
- Docs: `docs/domain/entities.md`, `docs/domain/tags.md` (MVP content больше не «только text body»).
- Зависит от archived `training-plans-tags`. Целевая модель фаз 2–3 фиксируется в `design.md` этого change, код фаз 2–3 не входит.
