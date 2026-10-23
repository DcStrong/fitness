# Сборка Flutter web + раздача через Caddy (HTTPS автоматически).
FROM ghcr.io/cirruslabs/flutter:stable AS build
ARG API_BASE_URL
WORKDIR /src
COPY app/fitness_app/ ./
RUN flutter pub get
# --no-web-resources-cdn: CanvasKit (wasm, ~2 МБ по сети со сжатием) отдаётся нашим Caddy, а не с gstatic.com (медленно/нестабильно в РФ).
RUN flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=${API_BASE_URL}

FROM caddy:2
COPY --from=build /src/build/web /srv
COPY deploy/Caddyfile /etc/caddy/Caddyfile
