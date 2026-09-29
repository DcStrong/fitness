## Why

После записи и lifecycle занятий продукту нужен **контент тренировки**: тренер создаёт простые планы и размечает их (и учеников) тегами, чтобы студенты видели релевантные программы. Сейчас в API/Flutter нет планов и тегов — фаза 6 закрывает этот пробел по [docs/domain/tags.md](../../../docs/domain/tags.md) и roadmap DoD («простой план + опционально тег»).

## What Changes

- Добавить домен **Tag** (владелец = создатель; уникальность `(creatorId, name)`).
- Добавить домен **TrainingPlan** (владелец-тренер; title + простое содержимое; без полноценного конструктора упражнений).
- Many-to-many: тег ↔ пользователи (`UserTag`), тег ↔ планы (`TrainingPlanTag`).
- Правила видимости: студент видит план тренера, с которым связан, если пересечение тегов студента и плана непустое (или явная политика MVP, зафиксированная в design).
- Permissions + seed для tags/plans; Nest API; тонкий Flutter UI (RU).
- Domain types в `src/<domain>/interface/` (как в остальных модулях).

## Non-goals

- Библиотека упражнений / структурированный workout builder / медиа.
- Иерархия тегов, глобальные публичные теги без владельца, автотегирование.
- Назначение плана на Session (`session.planId`) и «план дня» на главной.
- Soft-delete / версии планов / шаринг между тренерами.
- Web coach console.
- Групповые теги за пределами linked coach↔student.

## Capabilities

### New Capabilities

- `tags-api`: CRUD тегов владельца; назначение тега linked-студентам; list own / assigned.
- `plans-api`: CRUD training plans владельца-тренера; attach/detach tags; list own (trainer) / visible (student).
- `mobile-plans-tags`: Flutter UI — теги и планы для тренера; просмотр доступных планов для студента.

### Modified Capabilities

- `access-control`: новые permission codes для tags/plans и seed ролей trainer/student.
- `coach-student-link`: уточнение, что назначение тегов людям ограничено активной связью coach↔student (если нужно на уровне требований).
- `mobile-app-shell`: маршруты для планов/тегов.

## Impact

- Backend: новые модули `tags`, `plans` (или `training-plans`); entities + migrations; permissions seed; Postman.
- Flutter: `features/plans` / `features/tags` (или объединённый feature); go_router routes; Russian copy.
- Docs: при apply — краткое обновление domain notes при необходимости; roadmap после archive.
- Зависимости: существующие auth, permissions, coach-student links; без внешних сервисов.
