---
name: debug-api-error
description: Debug 4xx/5xx — exception filters, logs, tracing. Use when investigating API errors or Sentry issues.
---

# Debug API Error

1. Response body: `status`, `title`, `detail`, `validation[]`.
2. `AllExceptionFilter` — mapping domain → HTTP.
3. Structured logs + tracing (Sentry/OpenTelemetry).

Rule: `api-error-handling.mdc`

## Reference

[reference.md](reference.md)
