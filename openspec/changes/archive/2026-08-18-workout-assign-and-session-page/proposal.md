## Why

Шаблон тренировки бесполезен, если его нельзя выдать ученику и увидеть в календаре на конкретный слот. Сейчас тап по booked-сессии открывает только sheet «Проведена / Отменить / Неявка» — без состава, тегов и цели. Нужны copy-on-assign и полноценная страница занятия. Библиотека `/plans` спрятана за карточкой на Главной; теги есть API-экраном `/tags`, но без входа из UI.

## What Changes

- `POST /plans/:id/assign` создаёт `kind=student_copy` на каждого выбранного ученика (явно или через теги). Шаблон не меняется; повторный assign того же шаблона тому же ученику возвращает существующую копию.
- Правка копии не трогает шаблон и других учеников; правка шаблона не прокидывается в уже выданные копии.
- `GET /plans?kind=assigned` — копии ученика (тренер пары или сам студент).
- `sessions.student_plan_id` nullable; `PATCH /sessions/:id` привязывает копию ученика этой сессии.
- Привязка шаблона «на лету» с страницы занятия: clone-on-attach, если копии ещё нет.
- Flutter: «Назначить» с шаблона (ученики ∪ теги). Тап booked session → `/sessions/:id` (состав, теги, цель, время, ученик, абонемент remaining если есть, выбор тренировки, действия lifecycle). `SessionActionsSheet` больше не primary для booked session; free-slot sheets без изменений.
- Нижнее меню тренера: пункт «Тренировки» (иконка гантели / `Icons.fitness_center`) → `/plans`. Ученикский таб «Тренировки» → `/sessions` не менять.
- С библиотеки `/plans` открывается управление тегами (`/tags`: создать / список / удалить / назначить ученикам). В редакторе шаблона пустые теги ведут туда же, а не только текстом «сначала создайте».
- Каталог «База»: только зальные силовые (жим лёжа, присед со штангой, подтягивания, тяги, жимы…). Убрать бег/велосипед/эллипс и кардио вне зала из seed; идемпотентно заменить/удалить старые catalog rows.

## Non-goals

- Логи фактических подходов, графики, `/students/:id` hub — `workout-progress-and-student-hub`.
- Автопрокидывание правок шаблона в копии; программы на недели; лог от ученика; web.
- Изменение правил booking/lifecycle статусов и финансов.
- Отдельный таб нижнего меню «Теги» (теги живут внутри «Тренировки»).

## Capabilities

### New Capabilities

- `workout-assignments-api`: assign template → per-student copies; list assigned copies; idempotent re-assign.
- `mobile-session-workout`: Flutter session workout page and attach-workout flow (Russian).

### Modified Capabilities

- `plans-api`: `kind=student_copy`, assign endpoint, list assigned; mutate copy without mutating parent.
- `sessions-api`: optional `studentPlanId` on session read/update; attach must belong to session student.
- `mobile-calendar-views`: tap booked session opens the session page, not the manage sheet.
- `mobile-session-lifecycle`: complete/cancel/no-show/history live on the session page.
- `mobile-workout-templates`: template detail exposes «Назначить»; library exposes tag management.
- `mobile-app-shell`: trainer bottom nav includes «Тренировки» → `/plans` (dumbbell / fitness_center). Overrides layer-1 “no new tab”.
- `mobile-plans-tags`: tag CRUD/assign reachable from the plans library (existing `/tags` screen).
- `exercises-api`: gym-only catalog seed (no running/cycling).

## Impact

- Backend: use `parent_template_id` / `assigned_student_id` from structured-workout-templates; `sessions.student_plan_id` migration; plans assign service; sessions PATCH.
- Flutter: `/sessions/:id`, calendar navigation, assign sheet, student assigned list, trainer shell tab, tags entry from `/plans`, gym catalog seed.
- Depends on `structured-workout-templates`.
