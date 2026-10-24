## 1. Backend

- [x] 1.1 Entity `GymEntity`, `TrainerGymEntity`, репозитории, миграция `1755520000000-TrainerGyms`
- [x] 1.2 Модуль `gyms`: `GymsService` (attach/detach/list/suggest, дедуп по ключу, лимит 10), контроллер, DTO
- [x] 1.3 `GET /trainers`: фильтры `city`, `gymId`, `district`, `gymQuery`; `gyms[]` в карточке, профиле и `/profiles/me`
- [x] 1.4 Валидация телефона (`+7XXXXXXXXXX`) и специализаций (≤ 8, ≤ 30) в DTO и сервисе; миграция legacy-данных
- [x] 1.5 Unit-тесты `GymsService`, ключа дедупликации, валидации и каталога
- [x] 1.6 e2e: создание/дедуп зала, подсказки, фильтры, скрытый профиль, права, валидация
- [ ] 1.7 Postman-коллекция: новые запросы (OpenAPI/codegen в репозитории не ведётся)

## 2. Вне этого change

- [x] 2.1 Flutter: блок «Залы» в редакторе и фильтры в `trainers_page.dart` (поток D)
- [ ] 2.2 `docs/domain` / `map.md`: добавить домен gyms после архивации
