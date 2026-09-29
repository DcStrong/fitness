## Context

Fitness Yoda уже хранит auth identity, роли/permissions, связь тренер↔ученик и Session lifecycle. Профиля как доменной сущности нет: `User` содержит email, а существующие tags/plans/finance/history являются приватными рабочими данными. Социальный слой должен построить отдельную безопасную проекцию и не превратить продукт в открытый маркетплейс или соцсеть.

Flutter остаётся основным student-facing клиентом. Next.js — coach console: тренер редактирует публичное представление и видит отзывы, но web не получает student discovery. Backend является источником eligibility, privacy и rating policy.

## Goals / Non-Goals

**Goals:**

- Owner profile/privacy для обеих ролей с opt-in discoverability тренера.
- Публичная внутри продукта карточка тренера без PII и операционных данных.
- Пагинированная discovery-выдача опубликованных тренеров.
- Portfolio тренера и отзывы, подтверждённые completed Session.
- Производный рейтинг без mutable aggregate.
- Полный Flutter flow и coach-management flow в web.

**Non-Goals:**

- Anonymous internet directory, прямое бронирование из discovery или изменение invite-first relationship.
- Follow/friend/message/post/comment/reaction mechanics.
- Referral, complaint/admin moderation и trainer replies.
- Media upload/storage/processing.
- Публичные student profiles, session history, plans, internal tags, links или finance.

## Decisions

### 1. Профиль отделён от auth identity

`UserProfile` — 1:1 с `User`:

- `userId` (PK/FK);
- `displayName`, `avatarUrl`, `bio`;
- trainer fields: `city`, `specialties[]`, `trainingModes[]`;
- privacy: `isDiscoverable`, `showRating`, `showReviews`, `showReviewerName`;
- timestamps.

Профиль создаётся лениво через owner API либо миграционным default при первом update. Existing users остаются валидными без profile. `isDiscoverable=false` по умолчанию; student никогда не попадает в trainer discovery независимо от поля.

Альтернатива — добавить поля в `users`. Она отклонена: auth entity не должна одновременно быть публичной проекцией, а privacy/select mistakes повышают риск утечки email/password metadata.

### 2. Owner DTO и discover DTO — разные контракты

Owner endpoints:

- `GET /profiles/me`;
- `PUT /profiles/me`;
- `PUT /profiles/me/privacy`.

Discovery:

- `GET /trainers?page&limit&query&specialty&mode`;
- `GET /trainers/:id`;
- `GET /trainers/:id/reviews?page&limit`.

Discovery требует authenticated `profiles:read_public`; это «публично внутри продукта», а не anonymous internet endpoint. DTO никогда не содержит email, roles, permissions, student IDs, links, sessions, plans, tags или finance. Hidden trainer возвращает `404` для не-owner; owner preview использует owner DTO.

Если viewer — student, карточка MAY вернуть только viewer-scoped `isLinked`, чтобы объяснить CTA. Она не раскрывает чужие связи и не создаёт relationship. Запись остаётся доступна только после QR invitation.

### 3. Discovery — фильтрованная проекция, не social feed

Выдача включает опубликованных trainers с display name, avatar, short bio, city, specialties, modes и разрешёнными rating fields. MVP использует page/limit (default 20, max 50), `ILIKE` по имени/городу и exact filters по allowlisted specialties/modes. Стабильная сортировка: rating DESC, review count DESC, userId ASC.

Отдельные posts/follows/recommendation algorithm не создаются. PostgreSQL indexes достаточно для MVP; full-text/search service отложен.

### 4. Portfolio хранится отдельно и упорядочивается owner-ом

`TrainerPortfolioItem`:

- `id`, `coachId`;
- `title`, optional `description`, optional HTTPS `imageUrl`;
- `sortOrder`, timestamps.

Только trainer с `portfolio:manage_own` управляет максимум 20 items. Public projection включает items только для discoverable profile. Backend не скачивает URL и не обрабатывает файлы; клиенты применяют безопасное image fallback.

Альтернатива — использовать `TrainingPlan` — отклонена: plans содержат рабочую программу и student visibility, а portfolio является маркетинговой публичной проекцией.

### 5. Review eligibility закреплена за completed Session

`SessionReview`:

- `id`;
- `sessionId` unique;
- denormalized owner keys `coachId`, `studentId` для ownership/filtering;
- `rating` 1..5, optional `text`;
- timestamps.

Создание:

- `POST /sessions/:sessionId/review`;
- actor имеет `reviews:create_own`;
- actor равен `Session.studentId`;
- Session status строго `completed`;
- coach берётся только из Session;
- unique constraint гарантирует один review на Session при гонке.

Студент может исправить свой отзыв через `PUT /reviews/:id` с `reviews:update_own`; trainer не редактирует и не удаляет отзыв. Delete/moderation отложены, чтобы rating history не исчезала без audit policy.

`GET /reviews/eligible` возвращает собственные completed Sessions без review, а `GET /reviews/mine` — собственные отзывы. Trainer owner endpoint возвращает отзывы о нём без раскрытия student email.

### 6. Privacy управляет публикацией и атрибуцией

- `isDiscoverable=false`: профиль, portfolio, public reviews и rating отсутствуют в discovery/direct read.
- `showReviews=false`: список review text скрыт, но owner всё ещё видит отзывы.
- `showRating=false`: public `averageRating`/`reviewCount` не возвращаются.
- `showReviewerName=false` у student: public author — «Ученик» без ID/avatar; true разрешает только displayName/avatar public projection.

Privacy update применяется немедленно на чтении, без копирования публичных данных в отдельную таблицу. Existing operational APIs не меняют права: linked users по-прежнему получают только данные, уже предусмотренные relationship/session contracts.

### 7. Рейтинг вычисляется из review rows

`averageRating` и `reviewCount` считаются `AVG/COUNT` по reviews тренера. Mutable rating columns не создаются. Для списка trainers используется grouped query; индексы `(coach_id, created_at)` и unique `session_id` поддерживают чтение и integrity.

Это проще и проверяемее для текущего объёма. Materialized/cached aggregate возможен позже с reconciliation job.

### 8. Permissions и ownership

Каталог:

- `profiles:read_public`;
- `profiles:update_own`;
- `profiles:manage_privacy`;
- `portfolio:manage_own`;
- `reviews:read`;
- `reviews:create_own`;
- `reviews:update_own`.

Trainer получает public read, own profile/privacy/portfolio и review read. Student получает public read, own profile/privacy, review read/create/update. Guard permission всегда дополняется ownership/status/visibility checks; role-name не заменяет resource authorization.

### 9. Client boundaries

Flutter:

- repository/models + Bloc/Cubit;
- `/trainers`, `/trainers/:id`, `/reviews/new`, `/profile`, `/profile/privacy`;
- student navigation «Тренеры / Тренировки / Профиль»;
- trainer сохраняет существующий operational home и получает profile/privacy entry;
- completed Session показывает review CTA из backend eligibility.

Web:

- `/profile` coach-only;
- profile/privacy form, portfolio CRUD/reorder, owner preview и read-only reviews;
- sidebar entry «Публичный профиль»;
- student по-прежнему не допускается в coach console.

Image upload dependency не добавляется. UI — русский; состояния loading/empty/error/privacy-hidden обязательны.

### 10. Validation и limits

- `displayName`: 2..80;
- `bio`: max 1000;
- `city`: max 120;
- specialties: max 10 unique normalized strings, each max 40;
- modes: allowlist `online|offline`;
- avatar/image URL: HTTPS, max 2048;
- portfolio title 1..120, description max 1000;
- review text max 2000, rating integer 1..5;
- pagination max 50.

Backend нормализует whitespace и rejects unknown values. Public text рендерится как plain text; HTML не принимается.

## Risks / Trade-offs

- [PII accidentally enters public DTO] → Отдельные returns/mappers, contract tests на отсутствие email/IDs/permissions/finance.
- [Hidden profile can be enumerated by UUID] → `404` для hidden/non-trainer и одинаковое поведение not-found.
- [Forged or duplicate review] → Session-derived coach/student, transaction, unique `session_id`, ownership tests.
- [Rating query slows discovery] → indexes + bounded pagination; cache only after measurement.
- [Remote image tracks viewers or breaks UI] → HTTPS-only URLs, no backend fetch, client fallback; managed media later.
- [Student attribution changes after review] → Privacy checked at read time; reviewer identity is not copied into review.
- [Seed changes do not update existing JWT immediately] → Document re-login/refresh for new permissions.
- [Discovery suggests direct booking] → UI explicitly shows invitation requirement and never calls booking before link exists.
- [Profile arrays become uncontrolled taxonomy] → normalization/limits in MVP; managed specialization catalog later.

## Migration Plan

1. Migration creates `user_profiles`, `trainer_portfolio_items`, `session_reviews`, checks/FKs/indexes; no public profile backfill.
2. Seed new permissions; existing accounts refresh JWT.
3. Deploy backend owner/profile/review APIs with all profiles hidden by default.
4. Deploy Flutter profile/privacy then discovery/reviews.
5. Deploy web coach profile management.
6. Trainers explicitly publish after completing required display fields.

Rollback before public data: revert migration. After profiles/reviews exist, export/backup before destructive downgrade; hiding all profiles is the safe operational rollback.

## Open Questions

Нет блокирующих. Для MVP принято:

- discovery доступен только authenticated users;
- invite-first booking не меняется;
- one review per completed Session, review можно редактировать, но не удалять;
- no media upload and no moderation;
- ratings remain derived.
