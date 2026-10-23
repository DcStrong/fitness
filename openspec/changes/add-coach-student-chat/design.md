## Context

Связь тренер↔ученик уже есть: `coach_student_links` (уникальная пара, создаётся по инвайту или при принятии заявки), `GET /relationships/me`. Переносы сейчас живут в нескольких местах: отмена занятия (`sessions/:id/cancel`), заявки с альтернативным временем (`booking-requests/:id/alternate|accept|reject`), разовый перенос регулярного занятия (`recurring-bookings/:id/occurrences/:date/resolve`, `type: reschedule|skip`), запись тренером (`POST /sessions`).

Инфраструктуры реального времени нет: один инстанс Nest, нет WebSocket/SSE, нет Redis, нет push. Во Flutter есть пример периодического обновления (`HomeCubit`, `Timer.periodic`).

Доски: «Чаты» (список: аватар, имя, превью, время, бейдж непрочитанных, «Вы:» для своих), «Переписка» (шапка с именем и подзаголовком «Следующее: …», пузыри, разделитель дня, карточка системного события «Занятие перенесено» с плиткой времени и статус-чипом, композер), «Чат ученика» (тот же тред прямо во вкладке, без «назад»).

## Goals / Non-Goals

**Goals:** текстовая переписка в паре тренер↔ученик; непрочитанные в списке и на вкладке; события занятий видны в треде как системные карточки; доставка при открытом приложении — сразу (WebSocket).

**Non-Goals:** push, вложения (в плане как `add-chat-attachments`, после push), правка/удаление, «печатает», статус «прочитано» у собеседника, групповые чаты, web-консоль.

## Decisions

### 1. Транспорт: WebSocket (socket.io) + REST

Решение Ильи 2026-10-23: WebSocket сразу, без промежуточного polling.

- **Сервер:** `@nestjs/websockets` + `@nestjs/platform-socket.io`, namespace `/chat`, тот же HTTP-порт. Авторизация в handshake: `auth.token` = access JWT (тот же секрет, что у REST). Без валидного токена или без `chat:read_own` соединение закрывается.
- **Комнаты:** каждый сокет входит в комнату `user:<id>`. Сервер шлёт события обоим участникам диалога: `message.created` (полное сообщение + `conversationId`), `conversation.read` (`conversationId`, `readerId`, `lastReadAt`).
- **Запись — по REST.** Отправка, прочтение и история идут через HTTP: валидация DTO, права, идемпотентность по `clientId` уже работают там. WebSocket — канал доставки «сервер → клиент». Так меньше двойной логики и проще тестировать.
- **Публикация после коммита.** Сервисы собирают созданные сообщения внутри транзакции и публикуют их только после её успешного завершения: откатилось событие — никто не увидел сообщение.
- **Пропуски.** При (пере)подключении клиент догружает пропущенное REST-запросом `after=<lastId>`; сокет не гарантирует доставку, источник правды — БД.
- **Масштаб.** Один инстанс API — комнаты в памяти. При горизонтальном масштабировании добавляется Redis-адаптер socket.io, контракт не меняется.
- **Push** при закрытом приложении WebSocket не решает — это поток `add-notifications`.

### 2. Хранение

`chat_conversations`
| колонка | тип | |
|---|---|---|
| id | uuid PK | |
| coach_id, student_id | uuid FK users, CASCADE | UNIQUE (coach_id, student_id) |
| last_message_at | timestamptz null | сортировка списка |
| coach_last_read_at, student_last_read_at | timestamptz null | непрочитанные по стороне |
| created_at | timestamptz | |

`chat_messages`
| колонка | тип | |
|---|---|---|
| id | uuid PK | |
| conversation_id | uuid FK CASCADE | INDEX (conversation_id, created_at, id) |
| sender_id | uuid FK users null | null у системных |
| kind | varchar(16) | `text` \| `system` |
| body | text | ≤ 4000 символов после trim, не пустой для `text` |
| system_type | varchar(32) null | см. п. 4 |
| payload | jsonb null | `sessionId`, `startsAt`, `endsAt`, `previousStartsAt`, `status`, `note` |
| client_id | uuid null | UNIQUE (conversation_id, sender_id, client_id) — идемпотентная отправка |
| created_at | timestamptz | |

- Один диалог на пару, создаётся лениво (первое сообщение, первое системное событие или `POST /chats`). Не привязан к `coach_student_links.id`, чтобы переживать пересоздание связи.
- Непрочитанные = сообщения с `created_at > <моя>_last_read_at` и `sender_id ≠ я` (системные считаются). Отдельная таблица прочтений не нужна при двух участниках.
- Хранение без срока, удаление вместе с пользователем (CASCADE).

### 3. API и права

Права `chat:read_own`, `chat:send_own` выдаются ролям trainer и student в `seed.ts`.

| Метод | Право | Что делает |
|---|---|---|
| `GET /chats` | read_own | мои диалоги: собеседник (`id`, `displayName`, `email`), последнее сообщение, `unreadCount`, `lastMessageAt`; сорт по `lastMessageAt desc`; `?q=` фильтр по имени/почте |
| `POST /chats` `{counterpartId}` | read_own | get-or-create диалога; 403 без активной связи |
| `GET /chats/unread-count` | read_own | `{ total }` для бейджа вкладки |
| `GET /chats/:id/messages?before=&after=&limit=` | read_own | страница по курсору, limit ≤ 100, по умолчанию 50 |
| `POST /chats/:id/messages` `{clientId, body}` | send_own | отправка; повтор с тем же `clientId` вернёт то же сообщение |
| `POST /chats/:id/read` `{upToMessageId}` | read_own | двигает мой `last_read_at` (только вперёд) |

Правила доступа:
- Читать диалог может только его участник (иначе 404, чтобы не раскрывать существование).
- Писать можно только при активной связи coach_student_links для пары; чужой диалог — 404, нет связи — 403.
- Тренер и ученик различаются по роли в паре, а не по роли пользователя (ученик пишет только своим тренерам, тренер только своим ученикам).
- Rate limit в v1 не делаем; ограничение длины 4000 и валидация DTO.

### 4. Системные сообщения

`ChatSystemMessageService.post(manager, {coachId, studentId, type, payload, actorId})` вызывается из существующих сервисов **внутри их транзакции** (тот же `EntityManager`), чтобы сообщение не появилось без события и наоборот. Модуль `chat` экспортирует сервис, остальные модули его импортируют (без шины событий: CQRS в проекте не используется).

| system_type | Откуда | Текст в треде |
|---|---|---|
| `session_booked` | тренер записал ученика (`POST /sessions`) | «Новое занятие» + карточка |
| `session_cancelled` | `sessions/:id/cancel` | «Занятие отменено» + причина, если есть |
| `session_rescheduled` | `recurring …/resolve type=reschedule` | «Занятие перенесено» + было/стало |
| `occurrence_skipped` | `recurring …/resolve type=skip` | «Занятие пропущено» |
| `request_accepted` | `booking-requests/:id/accept` | «Заявка принята» + карточка |
| `request_alternate` | `booking-requests/:id/alternate` | «Предложено другое время» + карточка |
| `request_rejected` | `booking-requests/:id/reject` | «Заявка отклонена» |

- Текст рисует клиент по `system_type` + `payload` (так строки остаются в приложении). Сервер дополнительно кладёт русский `body` как запасной вариант для старых клиентов и превью в списке.
- Новая заявка ученика (`POST /booking-requests`) системным сообщением не пишется: у тренера уже есть инбокс заявок, дубль шумит.
- Карточка в треде ведёт на экран занятия (`/sessions/:id`), если `sessionId` есть.

### 5. Flutter

- `lib/features/chats/`: `data/chats_repository.dart` (dio), `cubit/chat_list_cubit.dart`, `cubit/chat_thread_cubit.dart`, `presentation/chats_page.dart`, `presentation/chat_thread_page.dart`, виджеты `chat_bubble`, `chat_system_card`, `chat_composer`, `chat_day_divider`.
- Роуты: `/chats` (вкладка), `/chats/:id` (тред тренера, с «назад»). У ученика вкладка «Чат»: 1 тренер → сразу тред без «назад» (как на доске); несколько → список; 0 → пустое состояние «Тренер появится после приглашения».
- Сокет: `socket_io_client`, подключение после логина, переподключение с backoff, на reconnect — догрузка `after` в открытом треде и обновление списка. `ChatRealtime` — один на приложение, кубиты подписываются на его поток.
- Отправка оптимистичная: пузырь с `clientId` сразу в треде, при ошибке — иконка «Не отправлено» + повтор по тапу. Порядок сообщений по `createdAt` сервера.
- Прочтение: при открытом треде и новых входящих — `POST /read` с последним id (с дебаунсом).
- Точки входа «Написать»: карточка ученика (`/students/:id`), профиль ученика (карточка тренера). Шапка треда тренера: иконка «Записать на занятие» → `/schedule/book-for-student` с предвыбранным учеником.
- Бейдж непрочитанных на вкладке Чаты/Чат через `FyIconBadge`/count badge в shell.
- Подзаголовок шапки «Следующее: сегодня, 11:00» берётся из уже существующего списка занятий пары, без нового API.

## Risks / Trade-offs

- Долгоживущие соединения: на мобильных сеть рвётся; спасает reconnect + догрузка по курсору.
- Комнаты в памяти процесса: при втором инстансе API без Redis-адаптера часть событий не дойдёт.
- Без push ученик узнаёт о сообщении только открыв приложение. Явно фиксируем, что push — следующий поток.
- Системные хуки трогают три сервиса; риск сломать их транзакции. Покрываем e2e на каждый тип события.

## Migration Plan

Одна миграция TypeORM (`chat_conversations`, `chat_messages`, индексы), права через seed. Обратная миграция удаляет таблицы. Бэкфилл истории событий в чат не делаем.

## Решения по открытым вопросам (Илья, 2026-10-23)

1. Транспорт — WebSocket сразу.
2. Вложения — после, внесены в `docs/roadmap/plan.md` как `add-chat-attachments`.
3. Список системных событий — ок.
