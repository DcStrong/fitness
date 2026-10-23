# Сборка Flutter web + раздача через Caddy (HTTPS автоматически).
FROM ghcr.io/cirruslabs/flutter:stable AS build
ARG API_BASE_URL
WORKDIR /src
COPY app/fitness_app/ ./
RUN flutter pub get
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM caddy:2
COPY --from=build /src/build/web /srv
COPY deploy/Caddyfile /etc/caddy/Caddyfile
