# Auth flow (platform)

```
HTTP Request
  → AuthorityMiddleware (global, парсит JWT → request.authority)
  → JwtAuthGuard (контроллер, отклоняет invalid/missing)
  → @Authority() param decorator (читает AuthorityModel в handler)
  → Service + DomainPolicy
```

## Исключения

- Internal controllers — без guard (service-to-service).
- Webhook/incoming — отдельная схема (API key, mTLS и т.д.) — описать в `project/rules/`.

## Эталон кода

- Class guard: `examples/controller/class-level-guard.ts`
- Internal: `examples/controller/internal-no-guard.ts`
