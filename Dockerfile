# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM dart:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM debian:bookworm-slim

WORKDIR /app

COPY --from=builder /app/bin/server ./bin/server
COPY --from=builder /app/assets ./assets

RUN chmod +x ./bin/server

EXPOSE 8080

CMD ["./bin/server"]