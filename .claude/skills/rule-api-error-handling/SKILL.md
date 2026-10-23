---
name: rule-api-error-handling
description: HTTP exceptions and global filter
---
<!-- pipil-sync: из .cursor/rules/api-error-handling.mdc. Правьте источник — копию обновит «Синхронизировать правила». -->

# API Error Handling

- Базовый тип: `BaseHttpException` — `{ status, title, detail, type? }`.
- 422: `ValidationErrorHttpException` + `validation[]`, `application/problem+json`.
- Global `AllExceptionFilter` + error reporter (Sentry и т.д.).

```typescript
// ✅ assertHaveAccess(...) → NoAccessHttpException
// ❌ throw new Error('denied') без HTTP mapping
```

Доменные ошибки без Nest deps → map в filter.

Skill: `debug-api-error`.
