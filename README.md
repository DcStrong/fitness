# Fitness Yoda

Платформа для тренеров и студентов: запись на занятия, календарь, планы, QR-приглашения.

## Документация

См. **[docs/README.md](docs/README.md)** — продукт, домен, стек, план.

Источник идей: [Miro board](https://miro.com/app/board/uXjVPLnb8m8=/).

## Репозиторий

| Путь | Состояние |
|------|-----------|
| `backend/api/` | NestJS API (auth, schedules, sessions, plans, tags…) |
| `app/fitness_app/` | Flutter (mobile MVP) |
| `web_app/` | Next.js консоль тренера |
| `docs/` | продуктовая документация |
| `openspec/` | specs / changes |

## Backend (local)

Параметры БД: `backend/.env` (не коммитится). Шаблон: `backend/.env.example`.

```bash
# DB (если ещё не поднята)
docker compose up -d postgres

# API
cd backend/api
cp ../.env .env   # или используй уже созданный backend/api/.env
npm install
npm run migration:run
npm run db:seed
npm run start:dev
```

Проверка:

```bash
curl http://localhost:3001/health
# {"status":"ok"}
```

Auth (кратко):

- `POST /auth/register` `{ "email", "password", "role": "trainer"|"student" }`
- `POST /auth/login` `{ "email", "password" }`
- `POST /auth/refresh` `{ "refreshToken" }`
- `POST /auth/logout` `{ "refreshToken" }`
- `GET /users/me` + `Authorization: Bearer <accessToken>`

## Mobile

```bash
cd app/fitness_app && flutter pub get && flutter run
```

## Web (консоль тренера)

```bash
cd web_app
cp .env.example .env.local
npm install
npm run dev
```

Откройте http://localhost:3000 (API по умолчанию на `:3001`).
