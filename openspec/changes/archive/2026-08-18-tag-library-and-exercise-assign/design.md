## Context

Теги уже связывают ученика и **шаблон** (`user_tags` ∩ `training_plan_tags` → `GET /plans/visible`). Copy-on-assign (`POST /plans/:id/assign`) выдаёт независимую `student_copy`. В UI чипы фильтра есть только в библиотеке «Мои»; экрана «кто/что с тегом» нет; упражнения тегов не имеют. «Назначить» открывается с **одной** карточки шаблона.

## Goals / Non-Goals

**Goals:**

- Найти учеников, тренировки и упражнения по тегу (хаб + фильтры).
- Live-видимость: общий тег тренера на ученике и на контенте открывает шаблоны **и** упражнения.
- Упражнения — отдельный каталог; можно выдать N штук ученику без шаблона.
- Несколько шаблонов → один ученик за один сценарий.
- Диалог нового тега не падает на Back/Esc.

**Non-Goals:** авто-копии при теге; sync шаблон→копии; привязка «россыпи» упражнений к Session; student hub/прогресс; web; новый bottom-tab.

## Decisions

### 1. Два канала, не смешивать

| Канал | Планы | Упражнения |
| --- | --- | --- |
| Тег (live) | уже `GET /plans/visible` | новый `GET /exercises/visible` |
| Явная выдача | `student_copy` (как сейчас) | join `student_exercises`, без клонирования строки упражнения |

Тег **не** создаёт копии. Правка шаблона/тегов сразу видна ученику в visible. Копия — когда нужна персональная программа или слот в календаре.

Альтернатива «тег = assign всех шаблонов копиями» отвергнута: плодит копии и расходится с live «ноги».

### 2. Теги на упражнениях

Таблица `exercise_tags (exercise_id, tag_id)` UNIQUE, как `training_plan_tags`. Тег принадлежит тренеру; catalog seed (`owner_coach_id` null) **можно** тегировать своим тегом — строка упражнения не меняется. Чужой тег на чужом own-exercise запрещён.

`POST/PATCH /exercises` принимает `tagIds` (свои теги). Catalog: `PUT /exercises/:id/tags` `{ tagIds }` без изменения name/kind.

### 3. Явная выдача упражнений

`student_exercises (coach_id, student_id, exercise_id)` UNIQUE. `POST /exercises/assign` `{ exerciseIds, studentIds?, tagIds? }` — тот же union linked студентов, что у plans assign. Идемпотентно. Unassign: `DELETE /exercises/assign` или DELETE по паре.

Студент видит объединение: tagged visible ∪ явно выданные (от linked coach).

### 4. Хаб тега

`GET /tags/:id` для создателя: `{ id, name, users[], plans[] (templates), exercises[] }`. Существующий `GET /tags/:id/users` остаётся. Студент этот хаб не читает (только свои теги списком).

Фильтр списков: `GET /plans?tagId=` (own templates), `GET /exercises?tagId=`. Клиентские чипы на `/plans` уже есть — оставить; хаб — канонический «найти по тегу».

### 5. Несколько тренировок одному ученику

API уже позволяет N разных шаблонов (unique только пара template+student). Добавить `POST /plans/assign-batch` `{ studentId, planIds[] }` **или** клиентский цикл существующих `POST /plans/:id/assign`. Предпочтение: **один batch endpoint** (меньше round-trips, одна транзакция на ошибки).

UI: режим выбора на «Мои» → sheet одного ученика; либо sheet «Назначить ученику» с мультивыбором шаблонов (инверсия текущего assign sheet).

### 6. Flutter IA

- `/tags/:id` — хаб (из списка тегов). Create-dialog — StatefulWidget, контроллер в `State.dispose` (уже починен в этом же цикле).
- `/tags` назад: `pop` иначе `/plans`.
- Библиотека `/plans`: сегменты «Мои | База | Упражнения». Упражнения не смешивать со шаблонами. Теги на карточке упражнения; «Назначить» → ученики ∪ теги.
- Ученик: visible планы **и** visible упражнения (тот же `/plans?visible=1` двумя секциями, без нового таба).
- Поиск учеников по тегу: хаб тега + фильтр чипами там, где уже есть список связанных учеников (assign sheets).

### 7. Permissions

Студент: `exercises:read_visible` (seed) на `GET /exercises/visible`. Trainer `exercises:manage_own` покрывает теги и assign. Не использовать `exercises:read_own` ученика как «все упражнения тренера».

## Risks / Trade-offs

- [Путаница visible vs assigned copies] → UI подписи: «По тегу» vs «Назначенные копии».
- [Тег на catalog exercise виден только студентам этого тренера] → фильтр по `tag.creatorId` = linked coach.
- [Batch assign частично упадёт] → транзакция: все или 403/400, без полузаписей.
- [Хаб раздувается] → списки id+title без nested sets.

## Migration Plan

1. `exercise_tags` + `student_exercises` + permission seed.
2. API: tags hub, exercise tags/visible/assign, plans assign-batch, `?tagId=`.
3. Flutter: dialog already fixed; hub; library segment; batch assign; student visible exercises.
4. Rollback: drop two tables; permission row leftover harmless.

## Open Questions

Нет. Привязка россыпи упражнений к Session — отдельный change, если понадобится после хаба ученика.
