---
name: rule-nestjs-controllers
description: Controllers — routing, guards, responses
---
<!-- pipil-sync: из .cursor/rules/nestjs-controllers.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# NestJS Controllers

Эталоны: `platform/examples/controller/`

| Сценарий | Файл |
|----------|------|
| POST command | `command-handler.ts` |
| GET list | `list-handler.ts` |
| Auth на классе | `class-level-guard.ts` |
| Internal без guard | `internal-no-guard.ts` |

Статические routes (`@Get()`) **до** `@Get(':id')`.

```typescript
// ✅ return new GetItemListResponseDto(list);
// ❌ return { data: dto.data, total: dto.total };
```

Auth flow: `examples/auth/middleware-guard-flow.md`, `auth-and-authority.mdc`.

Flow: `controller-api-flow.mdc`.
