## Why

Сейчас студент сразу создаёт `Session`, поэтому тренер не может подтвердить запрос, отклонить его с понятной причиной или согласовать другое время. Первый этап календарной стратегии вводит эксклюзивную заявку поверх существующих вручную созданных слотов и сохраняет финансовое начисление только для подтверждённой тренировки.

## What Changes

- **BREAKING**: заменить прямую самостоятельную запись студента в свободный слот на создание `BookingRequest` в статусе `pending`; `Session` и charge больше не создаются до решения тренера.
- Добавить lifecycle заявки `pending → accepted | rejected | withdrawn | expired`, owner-scoped списки для обеих сторон и permission-based API действий.
- Эксклюзивно удерживать слот одной pending-заявкой и разрешать одному ученику не более одной активной заявки к одному тренеру. Создание и решения выполняются атомарно с блокировкой и повторной проверкой доступности.
- Сохранять в заявке quoted price/currency. Срок ответа — 12 часов, но не позднее чем за 2 часа до начала слота; заявку без допустимого окна ответа создать нельзя.
- Разрешить ученику отозвать pending-заявку без причины. При отклонении требовать категорию `time_unavailable`, `plans_changed` или `other` и разрешить необязательный комментарий, видимый ученику.
- При выборе «Другое время» показать тренеру разрешённые контакты ученика и подсказку сначала согласовать перенос. После связи тренер указывает локальные дату и время; duration и mode копируются из исходного слота, а в одной транзакции создаются one-off slot, `Session`, charge и `accepted`-решение.
- Добавить обеим ролям профильный блок «Мои контакты»: телефон и Telegram, выбор одного или нескольких предпочтительных каналов, email как fallback. Контакты доступны только активному связанному тренеру/ученику, не входят в публичный профиль и используются в сценарии переноса.
- Обновить Flutter booking flow: студент отправляет и отслеживает заявки, тренер получает inbox со срочными заявками и действиями accept/reject/alternate, а Home тренера показывает счётчик pending с переходом в inbox.
- Добавить expiry processing и состояния loading/empty/error/conflict для мобильных экранов; realtime, push и внешние уведомления не требуются.

## Non-goals

- Недельные шаблоны доступности, `ScheduleSeries`, date overrides, массовая генерация слотов, buffers и усиление всех календарных overlap-ограничений — отдельный этап `recurring-availability`.
- Полноценный mobile day/week/month calendar, drag-and-drop и responsive week grid — отдельный этап `mobile-calendar`.
- Встроенный чат, встречные предложения с отдельным negotiation lifecycle или подтверждение нового времени учеником внутри приложения.
- Несколько одновременных pending-заявок одного ученика одному тренеру, waitlist, recurring bookings, group capacity и каталог услуг.
- Push, SMS, email-уведомления, интеграции WhatsApp/Google/Apple Calendar и проверка владения телефоном или Telegram.
- Публикация контактов в trainer discovery/public profile или доступ к ним без активной связи.
- Изменения web coach console.

## Capabilities

### New Capabilities

- `booking-requests-api`: создание, эксклюзивное удержание, expiry, owner-scoped чтение и решения accept/reject/alternate/withdraw для заявок на существующие слоты.

### Modified Capabilities

- `calendar-domain`: самостоятельная запись студента сначала создаёт pending-заявку; `Session` остаётся канонической тренировкой и создаётся только при принятии.
- `schedules-api`: held-слоты исключаются из доступности и защищаются от удаления/параллельной записи до терминального решения.
- `sessions-api`: student self-book заменяется заявкой, а подтверждение тренером атомарно создаёт booked Session из исходного или one-off слота.
- `session-finance`: quoted price фиксируется при заявке, но единственный pending charge создаётся только при её принятии.
- `coach-student-link`: создание заявки, решение и чтение предпочтительных контактов требуют активной связи тренер–ученик.
- `profile-privacy`: owner-профиль получает телефон, Telegram и предпочтительные каналы с linked-only проекцией и email fallback без попадания PII в public DTO.
- `access-control`: добавляются permission codes для создания, чтения и решений по заявкам и для чтения контактов связанного пользователя.
- `mobile-schedule-booking`: прямое подтверждение записи заменяется student request status flow и trainer request inbox.
- `mobile-social`: обе роли управляют контактами и предпочтительными способами связи в собственном профиле.
- `mobile-home-dashboard`: Home тренера показывает количество pending-заявок и ведёт в inbox.
- `mobile-app-shell`: добавляются защищённые role-aware маршруты списка и деталей booking requests.

## Impact

- Backend `backend/api`: новая TypeORM entity/migration/repository/service/controller для заявок, expiry job/use case, транзакционные изменения calendar/session/finance flows, contact fields/projections и permission seed.
- PostgreSQL: статусы и timestamps заявки, quoted amount/currency, решение и причина, ссылка на созданную Session, partial unique constraints для одного pending на slot и на coach–student pair.
- API: новые endpoints/DTO для заявок и linked contacts; прежний student `POST /sessions` меняет контракт и должен возвращать понятную ошибку либо быть закрыт permission migration после перехода клиента.
- Flutter `app/fitness_app`: repository/models, Bloc/Cubit, student request states, trainer inbox/decision sheets, alternate-time contact modal, профильные контакты и Home badge по правилам `docs/mobile/tooling.md`.
- Тесты: concurrent create/accept, expiry/withdraw/reject, quoted-price snapshot, one-pending limits, linked-only contact privacy, one-off alternate booking и widget-тесты основных мобильных состояний.
