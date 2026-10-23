#!/bin/sh
set -e
echo "==> Миграции"
npm run migration:run
if [ "${RUN_SEED:-true}" = "true" ]; then
  echo "==> Seed (роли, права, каталог, админ)"
  npm run db:seed
fi
echo "==> Запуск API"
exec node dist/main
