# Тестовый стенд: API целиком (с dev-зависимостями, чтобы запускать миграции и seed через ts-node).
FROM node:22-slim
WORKDIR /app
COPY backend/api/package.json backend/api/package-lock.json ./
RUN npm ci
COPY backend/api/ ./
RUN npm run build
COPY deploy/api/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENV NODE_ENV=production PORT=3001
EXPOSE 3001
ENTRYPOINT ["/entrypoint.sh"]
