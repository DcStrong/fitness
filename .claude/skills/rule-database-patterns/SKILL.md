---
name: rule-database-patterns
description: TypeORM entity and repository patterns
---
<!-- pipil-sync: из .cursor/rules/database-patterns.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Database Patterns

Эталоны: `platform/examples/repository/`

- Entity — только в repository layer; сервисы используют model/interface.
- Union колонок (status/mode) — в `src/<domain>/interface/`, entity только импортирует (`domain-interfaces`).
- `@Injectable()` repository, не extends `Repository<T>`.
- Узкие методы: `narrow-update.ts`.
- Сложная запись: `preload-save-reload.ts` — без mutate входной entity.

Skill: `repository-pure-persistence`. Migrations — `project-overview` scripts.

Transactions: `@Transactional()` в сервисе.
