## Why

После закрытия операционного MVP Fitness Yoda нужен слой доверия: тренер должен управлять публичным представлением и приватностью, а студент — находить открытые профили и оставлять подтверждённый отзыв только после состоявшегося занятия. Сейчас аккаунт содержит только email, поэтому публичная выдача либо бесполезна, либо рискует раскрыть персональные и операционные данные.

## What Changes

- Добавить профиль пользователя и privacy settings с безопасными defaults: профиль тренера не попадает в публичную выдачу без явного opt-in, профиль студента не становится публичным.
- Добавить публичный профиль тренера: display name, avatar URL, bio, специализации, форматы/локация, рейтинг и портфолио без email, permissions, финансов и истории занятий.
- Добавить пагинированную ленту/поиск только опубликованных тренеров; discovery не создаёт связь и не обходит существующий invite-first booking flow.
- Добавить отзывы, привязанные к `completed` Session: один отзыв студента на своё занятие, rating 1–5 и опциональный текст; рейтинг тренера вычисляется из видимых отзывов.
- Добавить Flutter discovery/profile/review/privacy flow и web-раздел тренера для управления публичным профилем, портфолио, приватностью и просмотра отзывов.
- Добавить permissions, TypeORM persistence, API, миграции, тесты и документацию для social/privacy домена.

## Non-goals

- Соцсеть общего назначения: подписки, друзья, личные сообщения, комментарии, реакции и пользовательские публикации.
- Прямая запись к незнакомому тренеру из discovery, замена QR-приглашений или публичное раскрытие слотов.
- Реферальная программа, жалобы/админ-модерация и ответы тренера на отзывы.
- Загрузка и обработка медиа-файлов: MVP хранит проверенные HTTPS URL для avatar/portfolio.
- Публичные профили студентов, публичная история тренировок, планы, теги учеников или финансовые данные.

## Capabilities

### New Capabilities

- `profile-privacy`: собственный профиль, owner-only privacy settings и безопасная публичная проекция.
- `trainer-discovery`: пагинированная выдача и публичная карточка только opt-in тренеров.
- `trainer-portfolio`: owner-managed упорядоченные portfolio items и публичное чтение через профиль.
- `session-reviews`: eligibility по completed Session, собственный отзыв студента и производный рейтинг тренера.
- `mobile-social`: Flutter-лента, публичный профиль, review flow и настройки приватности.
- `web-social`: web console для управления публичным профилем/портфолио/privacy и чтения отзывов.

### Modified Capabilities

- `access-control`: permissions для изменения собственного профиля/privacy/portfolio, создания собственного отзыва и чтения социальных данных.
- `mobile-app-shell`: authenticated social/profile routes и student-facing navigation.
- `web-coach-console`: навигация к разделу публичного профиля тренера.

## Impact

- Backend: новый `social`/`profiles` контур, TypeORM entities/repositories/migration, permission seed, public и authenticated API, rating queries и e2e/unit tests.
- Persistence: профиль/privacy 1:1 с User, portfolio items тренера, review 1:1 с completed Session; без денормализованного mutable rating.
- Flutter: repository/models/Bloc, discovery/profile/review/privacy screens; существующие auth/session/home flows получают точки входа.
- Web: coach-only public-profile editor, portfolio/privacy controls, preview и read-only reviews.
- Privacy/security: публичные DTO отделяются от owner DTO; email, UUID студента, permissions, links, sessions и finance не попадают в публичные ответы.
- Docs: social/privacy domain rules, entities/processes and roadmap terminology.
