## Context

Сейчас `ScheduleSlot` представляет доступность тренера, а `POST /sessions` немедленно и атомарно создаёт `Session`, `SessionCharge` и переводит слот из `open` в `booked`. Один и тот же endpoint обслуживает самостоятельную запись студента и прямую запись тренером. Отдельной сущности запроса, срока ответа, причин отклонения, уведомлений или переноса на другое время нет.

Flutter-клиент повторяет этот контракт: студент выбирает связанного тренера и открытый слот, после чего сразу получает тренировку. Тренер управляет вручную созданными слотами и может напрямую записать связанного ученика. Home загружает только Session текущего дня.

Изменение затрагивает календарь, финансы, профили, RBAC, Home и мобильную навигацию. При этом `Session` должен остаться канонической подтверждённой тренировкой, существующий coach book-for-student — работать напрямую, а недельные шаблоны доступности и полноценный календарь остаются последующими changes.

## Goals / Non-Goals

**Goals:**

- Ввести отдельную, аудируемую и owner-scoped заявку до создания Session.
- Эксклюзивно удерживать слот одной pending-заявкой и ограничить ученика одной pending-заявкой к одному тренеру.
- Сделать accept, reject, withdraw, expiry и alternate терминальными и конкурентно безопасными.
- Зафиксировать предложенную студенту цену при создании заявки, но создавать charge только при подтверждении.
- Дать тренеру разрешённые контакты связанного ученика и возможность назначить окончательное другое время после внешнего согласования.
- Добавить русские student/trainer flows во Flutter с Bloc/Cubit, явными состояниями и pending-счётчиком на Home.
- Сохранить прямую запись тренером, текущий Session lifecycle и privacy-safe public profile.

**Non-Goals:**

- Recurring availability, `ScheduleSeries`, date overrides, buffers и массовая генерация слотов.
- Полноценный day/week/month calendar, drag-and-drop и web coach console.
- Встроенный чат, встречные предложения и подтверждение альтернативного времени учеником.
- Push, SMS, email и интеграции внешних календарей или мессенджеров.
- Каталог услуг, recurring bookings, waitlist и групповые слоты.

## Decisions

### 1. BookingRequest является отдельным aggregate

Добавляется `booking_requests` с полями:

- идентификаторы `coachId`, `studentId`, `scheduleSlotId`;
- `status`: `pending | accepted | rejected | withdrawn | expired`;
- snapshot `quotedPriceMinor`, `quotedCurrency`;
- `expiresAt`;
- решение: `resolvedBy`, `resolvedAt`, `rejectionReason`, `rejectionComment`;
- `resolution`: `requested_slot | alternate_slot`;
- nullable `resolvedScheduleSlotId` и `sessionId`;
- timestamps.

`Session` не получает состояния `pending`/`rejected`: любой Session по-прежнему означает назначенную тренировку и следует существующему lifecycle `booked → terminal`. Для аудита добавляется append-only `booking_request_events`; создание и каждое терминальное решение записываются в той же транзакции.

Альтернатива — расширить `Session.status`. Она отклонена, потому что Session уже требует слот, создаёт финансовый snapshot и отображается Home как тренировка.

### 2. Pending-заявка логически удерживает слот без нового slot status

Слот остаётся `open`, но student availability query исключает слоты, на которые существует non-expired pending request. PostgreSQL partial unique indexes обеспечивают:

- не более одной строки `pending` на `schedule_slot_id`;
- не более одной строки `pending` на `(coach_id, student_id)`.

Создание заявки выполняется транзакционно: истёкшие заявки сначала переводятся в `expired`, слот блокируется `pessimistic_write`, повторно проверяются status, время, relationship и цена, затем создаются request и event. Конфликт unique index преобразуется в стабильный conflict response.

Новый `held` status у ScheduleSlot не вводится: hold принадлежит заявке, а терминальный request автоматически освобождает availability без дополнительной синхронизации двух статусов.

### 3. Срок ответа вычисляется на сервере

`expiresAt = min(createdAt + 12 hours, slot.startsAt - 2 hours)`. Если вычисленный deadline не находится в будущем, заявку создать нельзя. Серверное время и UTC timestamps являются источником истины.

`@nestjs/schedule` запускает идемпотентный expiry use case не реже одного раза в минуту. Перед create/list/decision availability-sensitive операции также вызывают bounded `expireDue(now)`, поэтому корректность не зависит от своевременности фонового tick. Expiry обновляет только `pending` строки с `expiresAt <= now` и добавляет request event.

Альтернатива — только cron. Она отклонена, потому что задержка или остановка процесса оставила бы ложные holds. Только lazy expiry также отклонён, потому что статус ученика мог бы долго оставаться stale без обращений к API.

### 4. Цена котируется при request, charge создаётся при accept

При создании заявки сервер читает положительную finance setting тренера и сохраняет amount/currency в request. Изменение default price после этого не меняет quote. Accept и alternate используют quoted price для единственного `SessionCharge`.

Charge до принятия не создаётся, поэтому pending/rejected/expired заявки не попадают в финансовые отчёты. Тренер не может изменить quoted price при решении заявки.

### 5. Решения выполняются одним транзакционным orchestration service

`BookingRequestsService` владеет lifecycle policy, а persistence repositories не принимают бизнес-решений.

- `accept`: lock request и исходный slot; проверить `pending`, срок, relationship и `slot.status=open`; создать Session/charge через общий calendar booking primitive; отметить slot booked, request accepted и записать event.
- `reject`: требовать reason enum, опциональный комментарий ограниченной длины; атомарно отметить request rejected и event.
- `withdraw`: разрешить только student-владельцу pending-заявки; атомарно отметить withdrawn и event.
- `alternate`: lock request и coach; проверить `pending`, relationship и диапазон; создать one-off `ScheduleSlot(seriesId=null)` с duration/mode исходного slot, затем Session/charge, request accepted с alternate resolution и event. Исходный слот остаётся open.

Calendar booking primitive расширяется явным quoted-price input для request acceptance, но прямой coach booking продолжает использовать текущую default/override политику.

Все изменения расписания, которые могут конкурировать с alternate (`createSlot`, direct booking, request accept/alternate), сериализуются блокировкой строки coach user внутри транзакции. Проверка alternate учитывает open slots и booked sessions. Полное PostgreSQL overlap hardening остаётся change `recurring-availability`.

### 6. Student direct booking закрывается на двух уровнях

Student role больше не получает `sessions:book_self`; вместо него выдаётся `booking_requests:create`. Дополнительно `POST /sessions` явно отклоняет actor-student, даже если старый JWT ещё содержит прежнее permission. Coach `sessions:book_for_student` остаётся без изменений.

Это позволяет безопасно пережить rolling deployment и старые мобильные клиенты. После обновления seed пользователь получает актуальные permissions при следующем login/refresh.

### 7. API разделяет student list и trainer inbox

Новые защищённые endpoints:

- `POST /booking-requests` — student создаёт request по slot;
- `GET /booking-requests/mine` — student читает собственные requests;
- `POST /booking-requests/:id/withdraw`;
- `GET /booking-requests/inbox` — trainer читает requests своих слотов, pending сначала по `expiresAt`;
- `GET /booking-requests/pending-count` — trainer получает lightweight count;
- `POST /booking-requests/:id/accept`;
- `POST /booking-requests/:id/reject`;
- `POST /booking-requests/:id/alternate`.

List endpoints поддерживают status и bounded pagination. Response содержит request status, requested/resolved slot summary, quote, deadline, counterpart safe label, reason/comment и `sessionId`, но не entity.

### 8. Контакты принадлежат owner profile и имеют linked-only projection

`user_profiles` получает nullable `phone`, `telegramUsername` и `preferredContactChannels` (`phone | telegram | email`). Телефон валидируется в нормализованном международном формате, Telegram — как username без URL. Канал phone/telegram нельзя выбрать preferred без соответствующего значения; email всегда доступен как fallback из User.

Own-profile read/update возвращает эти поля владельцу. Public trainer/profile/review projections всегда их исключают. Linked-contact endpoint возвращает только preferred заполненные каналы и email fallback, только если caller и target состоят в активной coach–student relationship. Booking request alternate response/flow использует эту projection, а не дублирует PII в request.

### 9. Flutter получает отдельную booking_requests feature

Добавляется `BookingRequestsRepository`, typed models и feature-scoped Cubit/Bloc:

- student page: отправка заявки, список «Мои заявки», статусы pending/accepted/rejected/withdrawn/expired и withdraw;
- trainer inbox: пагинация/refresh, pending-first сортировка, детали и decision sheets;
- alternate sheet: linked contacts, подсказка о внешнем согласовании, локальная дата/время и итоговое подтверждение;
- profile: редактирование контактов и preferred channels;
- Home: независимая загрузка pending count и переход в inbox.

Networking не размещается в widgets. Page предоставляет Cubit, View отображает loading/empty/success/failure/conflict. Ошибка pending count не должна ломать дневное расписание Home.

### 10. In-app visibility достаточна для первого этапа

Trainer видит inbox и badge после загрузки/refresh Home, student — актуальный статус в «Мои заявки». Realtime и внешняя доставка не обещаются. Все mutation screens после успеха обновляют соответствующие lists/counts через repository-backed Cubit actions.

## Risks / Trade-offs

- [Cron задержался или приложение перезапустилось] → lazy `expireDue` вызывается на всех availability-sensitive путях; обработка идемпотентна.
- [Старый student JWT всё ещё содержит `sessions:book_self`] → service-level запрет прямой student booking действует независимо от permission.
- [Два клиента одновременно создают/принимают заявку] → row locks, partial unique indexes и transaction boundaries; e2e проверяет exactly-once Session/charge.
- [Alternate пересекается с параллельной операцией] → coach row lock сериализует schedule mutations; следующий change добавит полноценные DB overlap constraints.
- [Цена изменилась во время ожидания] → request quote неизменяем и используется при accept.
- [PII утечёт в public DTO или logs] → контакты выдаются отдельной linked-only projection, public mapper имеет allowlist, DTO/privacy e2e проверяют отсутствие полей.
- [Одна pending-заявка к тренеру слишком ограничивает активного ученика] → это осознанное MVP-ограничение; после исследования поведения его можно ослабить до one-per-slot.
- [Нет push-уведомлений] → inbox, Home badge и pull-to-refresh делают состояние доступным, но не гарантируют немедленную реакцию вне приложения.

## Migration Plan

1. Добавить contact columns, booking request/event tables, CHECK/FK/indexes и новые permissions; существующие данные не требуют backfill.
2. Развернуть backend с новыми endpoints, expiry processor и service-level запретом student direct booking. Coach direct booking остаётся совместимым.
3. Обновить Flutter repository/models/profile и добавить student/trainer request flows, routes и Home count.
4. Обновить seed assignments; потребовать refresh/login для получения нового permission bundle.
5. Проверить migration rollback: сначала откатить Flutter, временно вернуть student direct booking, затем удалить request/contact schema только после отсутствия новых клиентов.

## Open Questions

Блокирующих вопросов нет. Значения 12 часов / 2 часа, одна pending-заявка на пару и email fallback приняты как MVP defaults и должны быть вынесены в именованные domain constants для последующей настройки.
