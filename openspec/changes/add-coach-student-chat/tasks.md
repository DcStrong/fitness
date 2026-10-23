## 1. Backend: модуль chat

- [ ] 1.1 Entity `ChatConversationEntity`, `ChatMessageEntity` + миграция (таблицы, UNIQUE, индексы)
- [ ] 1.2 Права `chat:read_own`, `chat:send_own` в `constants.ts` и `seed.ts` (trainer, student)
- [ ] 1.3 `ChatService`: list (с `q`), get-or-create по паре с проверкой связи, messages по курсору, send с идемпотентностью по `clientId`, read, unread-count
- [ ] 1.4 `ChatController` + DTO + OpenAPI
- [ ] 1.5 `ChatSystemMessageService.post(manager, …)` и вызовы из sessions (book, cancel), booking-requests (accept, alternate, reject), recurring-bookings (resolve)
- [ ] 1.6 Unit-тесты сервиса (доступ, непрочитанные, курсоры, идемпотентность)
- [ ] 1.7 e2e: чужой диалог 404, без связи 403, отправка/чтение/непрочитанные, по одному сценарию на каждый system_type

## 2. Flutter: данные

- [ ] 2.1 `ChatsRepository` (dio) и модели
- [ ] 2.2 `ChatListCubit` (polling 15 с при видимости, поиск)
- [ ] 2.3 `ChatThreadCubit` (история, `after`-polling 4 с, оптимистичная отправка, retry, read с дебаунсом)
- [ ] 2.4 Unread-count в shell + бейдж вкладки

## 3. Flutter: экраны по доскам

- [ ] 3.1 «Чаты» тренера: заголовок, поиск, строки диалогов, пустое состояние
- [ ] 3.2 «Переписка»: шапка, разделители дней, пузыри, системная карточка, композер
- [ ] 3.3 «Чат» ученика: 0/1/N тренеров
- [ ] 3.4 Кнопки «Написать» в карточке ученика и профиле ученика; «Записать на занятие» из шапки треда
- [ ] 3.5 Widget-тесты экранов и кубитов

## 4. Завершение

- [ ] 4.1 `flutter analyze`, `flutter test`, API unit + e2e зелёные
- [ ] 4.2 Обновить `.cursor/project/docs/map.md` (домен Chat)
