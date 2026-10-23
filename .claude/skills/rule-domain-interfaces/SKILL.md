---
name: rule-domain-interfaces
description: Domain types live in src/<domain>/interface/
---
<!-- pipil-sync: из .cursor/rules/domain-interfaces.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Domain Interfaces

В каждом домене — `interface/`: Params, Returns, models, union статусов/mode.

- Не объявлять `export type` / `export interface` в `*.entity.ts`, `*.service.ts`, корневом `types.ts`.
- Entity **импортирует** типы колонок из `interface/` владеющего домена.
- Публичные методы сервиса — явные `*Params` / `*Returns` (`service-types-and-null.mdc`).

Skill: `domain-interfaces`. Рефакторинг: skill `refactor-prompt.md`.
