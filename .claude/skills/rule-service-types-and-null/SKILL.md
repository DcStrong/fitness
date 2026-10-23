---
name: rule-service-types-and-null
description: Service Params/Returns, null and PATCH semantics
---
<!-- pipil-sync: из .cursor/rules/service-types-and-null.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# Service Types и null

| Слой | Паттерн |
|------|---------|
| Service method | `routeXxx` |
| Input | `RouteXxxParams` |
| Output | `RouteXxxReturns` |
| Repository | `*Params` per scenario |

`undefined` → не менять; `null` → очистить (если nullable в OpenAPI).

Merge — в **сервисе**, repository получает финальные значения (`examples/repository/preload-save-reload.ts`).

Типы в `interface/`, не внутри `service.ts`. Skill: `domain-interfaces`.
