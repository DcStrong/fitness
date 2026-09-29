## Context

Слой 1 (`structured-workout-templates`) даёт шаблоны с упражнениями. Session по-прежнему без контента; календарь открывает `SessionActionsSheet`. Колонки `parent_template_id` и `assigned_student_id` уже есть и NULL. Контракт copy-on-assign описан в design слоя 1 §7.

## Goals / Non-Goals

**Goals:**

- Выдать шаблон одному/нескольким ученикам (ID или тег) как независимые копии.
- Привязать копию к Session; показать состав на странице занятия.
- Календарный тап booked → `/sessions/:id`.
- Тренер открывает библиотеку `/plans` из нижнего меню (гантеля).
- Управление тегами доступно с этой библиотеки.
- Seed «База» — только зал.

**Non-Goals:** set logs, charts, student hub, template-to-copy sync, web, отдельный bottom-tab «Теги».

## Decisions

### 1. Copy-on-assign, не live link

`POST /plans/:id/assign` `{ studentIds?: uuid[], tagIds?: uuid[] }` — объединение linked студентов из ID и из `user_tags` для своих тегов. Пустой union → 400.

Для каждой пары (templateId, studentId): если уже есть `kind=student_copy` с тем `parent_template_id` и `assigned_student_id` — вернуть её. Иначе deep copy title/goal/notes/exercises/sets; `ownerCoachId` = тренер шаблона; теги копии = теги шаблона (видимость/фильтр). Unique index `(parent_template_id, assigned_student_id)` WHERE kind=student_copy.

Правка копии: тот же PATCH nested exercises, только owner coach. Студент read-only.

Альтернатива: одна шаблонная запись на всех + overlay дельт — отвергнуто (сложнее прогрессии и UI).

### 2. Session attach

Migration: `sessions.student_plan_id` uuid NULL FK `training_plans(id)` ON DELETE SET NULL.

`PATCH /sessions/:id` `{ studentPlanId }` — coach of session; plan MUST be `student_copy` for `session.studentId` and same coach. Null отвязывает.

Clone-on-attach: если с UI выбран `kind=template`, сервис сначала assign этому student, потом ставит `studentPlanId`. Клиент может вызвать assign+patch сам; API MAY принять template id и сделать это атомарно (`sourcePlanId`). Предпочтение: один `PATCH` с `planId` + `cloneIfTemplate: true` чтобы страница занятия делала один запрос. Проще два вызова с клиента (assign then patch) — меньше сюрпризов. **Решение: два вызова**, страница оркестрирует.

GET session includes optional nested plan summary (id, title, goal, tags, exercises).

### 3. Lists

- Trainer `GET /plans?kind=assigned&studentId=` — copies for that student (must be linked).
- Student `GET /plans?kind=assigned` — own copies from linked coaches.
- `GET /plans/visible` не заменяется.

### 4. Flutter

- Template detail: кнопка «Назначить» → sheet: поиск учеников (уже есть `student_search_select`) + чипы своих тегов. Confirm → assign.
- Calendar (`trainer_calendar_page.dart`): booked/non-terminal session tap → `context.push('/sessions/${id}')` вместо `SessionActionsSheet.show`. Terminal session тоже страница (read-only actions).
- `/sessions/:id`: header время/ученик/режим; goal+tags; compact exercises; package remaining chip if packages:read; CTA «Выбрать тренировку» если plan отсутствует; bottom actions reuse lifecycle permissions. History → existing history route.
- Attach picker: assigned copies этого ученика, иначе «из моих шаблонов» (assign+attach).
- Student: Home row / sessions list → та же страница, без complete/no-show.
- `SessionActionsSheet` оставить для list fallback только если страница ещё не открыта — **удалить как primary**; sessions_list_screen тоже пушит страницу.
- Library `/plans` app bar: действие «Теги» → существующий `TagsScreen` (`/tags`). Редактор: если тегов нет — CTA открыть `/tags`, не только текст.
- Карточка Главной «Планирование» может остаться; канонический вход — нижнее меню.

### 5. Permissions

Reuse `plans:update_own`, `plans:read_own`, `plans:read_visible`, `sessions:*`. No new codes unless assign needs `plans:create` (copy insert) — assign uses create+update_own of owner. Student cannot assign.

### 6. Trainer shell tab

Layer 1 явно не добавлял indexed destination. Здесь **добавляем** пятый пункт тренера:

`Главная | Расписание | Тренировки | Ученики | Профиль`

«Тренировки»: `Icons.fitness_center` / outlined pair, `location: '/plans'`, highlight `/plans` and `/plans/*` (не `/tags` как отдельный таб — `/tags` подсвечивает «Тренировки» через `activePathPrefixes: ['/plans', '/tags']`).

Студент: пункт «Тренировки» по-прежнему `/sessions`. Не подменять на `/plans`.

Пять пунктов + `onlyShowSelected` уже в shell.

### 7. Gym-only catalog seed

Переписать `catalog-workout-seed.ts` (идемпотентный upsert тех же UUID):

- Оставить/добавить зал: жим штанги лёжа, приседания со штангой, становая, тяга верхнего блока, жим гантелей, румынская, выпады, тяга в наклоне, жим ногами, подъём на бицепс, отжимания, подтягивания, гиперэкстензия, брусья, разгибание ног, подъём ног в висе / скручивания.
- Убрать кардио вне зала: «Велосипед», бег, эллипс. Kind `duration` только для зальных изометрик (планка) — опционально; жиросжигающие шаблоны строить из зальных `weight_reps` / `bodyweight_reps` с большим числом повторов, не из вело/берпи-круговой.
- UUID «Велосипед»: не delete если на него ссылаются копии тренеров — **переименовать** в зальное упражнение и сменить `kind` при необходимости; шаблоны каталога пересобрать без вело.
- Повторный seed не плодит строки.

## Risks / Trade-offs

- [Две копии одного шаблона если unique index не стоит] → partial unique index.
- [Ученик без тега не видит шаблон в visible, но получает copy] → это цель assign; visible остаётся групповым каналом.
- [Старые сессии без plan] → страница показывает CTA выбрать тренировку; complete без плана как сейчас.
- [Рекуррентные слоты] → каждая Session независимо получает studentPlanId; не автоназначаем на всю серию в v1 (можно позже).

## Migration Plan

1. `sessions.student_plan_id` + unique index on copies.
2. API assign + PATCH session.
3. Flutter page + calendar navigation + trainer tab + tags entry.
4. Gym catalog seed upsert.
5. Rollback: drop column; copies remain as plans (orphan copies ok); shell tab can revert independently.

## Open Questions

Нет. Серия recurring не копирует plan автоматически — явно в non-goals.
