---
name: add-database-entity
description: Entity, migration, repository, TypeOrmModule.forFeature. Use when adding a new database table/entity.
---

# Add Database Entity

1. Union/status/mode типы колонок — в `src/<domain>/interface/`, не в entity (skill `domain-interfaces`).
2. Entity в `database/entity/` — только класс; типы колонок через `import type`.
3. Migration — project script (`project-overview.mdc`).
4. Repository + `*Params` в `interface/` домена.
5. `TypeOrmModule.forFeature` в feature module.

Эталоны: `examples/repository/narrow-update.ts`, `preload-save-reload.ts`.

Rule: `database-patterns.mdc`, `domain-interfaces.mdc`. Skills: `repository-pure-persistence`, `domain-interfaces`.
