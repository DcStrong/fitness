# Debug API errors

- 422 → проверить DTO `@ValidateNested`, `@Type`, snake_case.
- 401/403 → middleware + guard + policy (`auth-and-authority.mdc`, project permissions).
- Domain error без HTTP → добавить mapping в filter.

E2E contract errors — эталон в `test/contract/`.
