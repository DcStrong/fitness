# Repository examples (platform)

См. `platform/examples/repository/` — self-contained, без путей `src/`.

Антипаттерн: передать loaded entity и мутировать поля in-place перед save.

Канон: сервис собирает `id`, `metaId`, финальные поля → repository preload/save/reload.
