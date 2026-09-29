---
name: domain-interfaces
description: >-
  Place domain interfaces and types in src/<domain>/interface/. Use when adding
  or moving types, Params/Returns, union statuses, models; when types live in
  entity/service/types.ts; or when refactoring typing in NestJS backend modules.
---

# Domain Interfaces

## Правило

В каждом логическом скоупе (домене) — директория `interface/`, где лежат **все** интерфейсы и доменные типы этого скоупа. Код должен быть явно типизирован: без анонимных object-literal в сигнатурах публичных методов и без `export type`/`export interface` в entity/service/controller.

## Куда класть

| Что | Где |
|-----|-----|
| Union статусов/mode, domain models | `src/<domain>/interface/*.types.ts` или `*.interface.ts` |
| Вход сервиса | `RouteXxxParams` / `XxxParams` → `interface/` |
| Выход сервиса | `RouteXxxReturns` / `XxxReturns` → `interface/` |
| Вход repository-сценария | `XxxParams` → `interface/` (владелец домена) |
| JWT/request payload домена | `interface/`, не корневой `types.ts` |

**Не класть типы в:** `*.entity.ts`, `*.service.ts`, `*.controller.ts`, `*.repository.ts`, корневой `types.ts`, `constants.ts` (кроме `typeof CONST[number]` рядом с const — тогда type рядом в `interface/` и re-export при необходимости).

Entity **импортирует** union-типы колонок из `interface/` владеющего домена. Entity не объявляет и не экспортирует типы.

## Именование файлов

```text
src/schedules/interface/
  schedule-slot.types.ts      # ScheduleSlotStatus, ScheduleSlotMode
  create-slot.params.ts       # CreateSlotParams
  create-slot.returns.ts      # CreateSlotReturns  (или рядом в одном файле, если крошечные)
  schedule-slot.model.ts      # публичная/сервисная форма без Entity
  index.ts                    # опциональный barrel
```

- `interface` / `type` — по смыслу: shape объекта → `interface`; union/alias → `type`.
- Один файл — одна связная группа (не сваливать весь домен в один mega-file без нужды).

## Чеклист при новом типе

1. Определи домен-владелец (`schedules`, `sessions`, `auth`, …).
2. Создай/дополни файл в `src/<domain>/interface/`.
3. Подключи импортом в service / repository / entity / DTO mapper.
4. Убери локальный `export type` и инлайн `{ ... }` из сигнатур.
5. Публичные методы сервиса: явные Params + Returns (см. `service-types-and-null.mdc`).

## Запрещено

- Типы «рядом с entity» (`export type` в `*.entity.ts`).
- Дублировать один union в двух модулях — один владелец, остальные импортируют.
- `any`, необоснованный `as`, анонимные input/output у `route*` / публичных методов.
- Тянуть Entity в interface-файлы (interface не знает TypeORM).

## Связанное

- Rule: `service-types-and-null.mdc`, `typescript-typing.mdc`, `module-boundaries.mdc`
- Skills: `add-feature-module`, `add-database-entity`, `repository-pure-persistence`
- Рефакторинг текущего кода: [refactor-prompt.md](refactor-prompt.md)
- Детали и примеры: [reference.md](reference.md)
