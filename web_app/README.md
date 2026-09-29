# web_app — консоль тренера

Next.js (App Router) клиент к Nest API. Mobile остаётся полным клиентом; web — desktop UX для тренера.

## Требования

- Node 20+
- Локальный API: `http://localhost:3001` (см. `backend/api`)

## Запуск

```bash
cd web_app
cp .env.example .env.local   # при необходимости
npm install
npm run dev
```

Откройте [http://localhost:3000](http://localhost:3000) → логин тренера.

Переменные:

| Переменная | Пример |
|------------|--------|
| `NEXT_PUBLIC_API_BASE_URL` | `http://localhost:3001` |

## Разделы

- Ученики, Слоты, Занятия (+ lifecycle/история), Теги, Планы, Приглашения (ссылка)

Студенческий аккаунт после входа увидит отказ «только для тренеров».
