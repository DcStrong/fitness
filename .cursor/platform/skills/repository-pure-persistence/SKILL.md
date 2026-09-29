---
name: repository-pure-persistence
description: Repository layer — persist only, no domain merge. Use when changing src/**/*.repository.ts.
---

# Repository Pure Persistence

## Разрешено

create, save, update, find*, filter, preload, технические QB helpers.

## Запрещено

PATCH merge в repository, mutate переданной entity, read-modify-write с бизнес-решениями.

## Эталоны

`platform/examples/repository/preload-save-reload.ts`, `narrow-update.ts`

## Детали

[reference.md](reference.md)
