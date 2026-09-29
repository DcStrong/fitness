# NestJS Platform (portable)

Копируйте папку `platform/` в `.cursor/platform/` любого NestJS-сервиса.

## Активация в репозитории

```bash
./.cursor/activate.sh
```

Скрипт объединяет `platform/rules` + `project/rules` → `.cursor/rules/` и копирует `platform/skills` → `.cursor/skills/`.

## Содержимое

| Папка | Назначение |
|-------|------------|
| `examples/` | Абстрактные сниппеты паттернов (не компилируются) |
| `rules/` | Обобщённые rules без путей `src/` |
| `skills/` | Workflow skills, ссылки только на `examples/` |

## Новый сервис

1. Скопировать `platform/`.
2. Создать `project/rules/project-overview.mdc` под свой стек.
3. Запустить skill `refactor-service-to-platform`.
4. Заполнить `project/docs/live-references.md` живыми путями репо.

### User-policy skill

Skill `user-policy` **не** входит в `platform/skills`. Он живёт в `project/skills/` только у сервисов, куда скопирован `permission/policy/portable`.

В самом skill первый шаг — gate: нет portable → skill не применять, работать через `PermissionService` как раньше.
