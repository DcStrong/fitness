# Источник: Miro-доска

Доска: [https://miro.com/app/board/uXjVPLnb8m8=/](https://miro.com/app/board/uXjVPLnb8m8=/)

Снято в документацию: 2026-07-17.

## Карта фреймов

| Фрейм | URL | Что зафиксировано в docs |
|-------|-----|---------------------------|
| Fitness Yoda | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536439406476) | `product/vision.md`, `product/roles-and-features.md` |
| Обзорная | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536436332315) | карта модулей |
| Связи | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536436332051) | `domain/invitations.md` |
| Детальная | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536395637329) | поток encode/decode |
| QR | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536439547443) | codec / QR |
| Тэги | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536653480335) | `domain/tags.md` |
| Палитра для темной темы | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536653415554) | `architecture/stack.md` (дизайн) |
| Запись клиента с приложением | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764536663121333) | `domain/processes.md` A |
| Запись клиентом тренером | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764537818006157) | `domain/processes.md` B (мало деталей на доске) |
| Подтверждение занятия | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764537818027307) | `domain/processes.md` C (пусто на доске) |
| Процесс со стороны клиента | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764546439192537) | карта сущностей |
| Процесс со стороны тренера | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764546441769112) | карта сущностей |
| DB Relations | [link](https://miro.com/app/board/uXjVPLnb8m8=/?moveToWidget=3458764546467064878) | `domain/entities.md` |

## Пробелы на доске (нужно допроектировать в docs/коде)

1. Фрейм записи тренером — почти без шагов.
2. Фрейм подтверждения занятия — пустой контейнер.
3. Нет явной state-machine для Session.
4. Нет UI-wireframes экранов (только модульная карта).
5. Палитра — картинка без точных токенов в тексте.
6. В DB Relations опечатка `Studen`, слабая нормализация `calendar[]`.

## Как обновлять

При изменении доски:

1. Пройти затронутые фреймы через Miro MCP (`context_explore` → `context_get` / `board_list_items`).
2. Обновить соответствующий файл в `docs/`.
3. Если меняется поведение продукта — завести OpenSpec change.
