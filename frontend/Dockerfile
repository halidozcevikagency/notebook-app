# ──────────────────────────────────────────────
# Stage 1: Flutter Web Build
# ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /build

# Flutter kaynak kodunu kopyala (build context köküne göre)
COPY notebook_app/ ./notebook_app/

WORKDIR /build/notebook_app

# Bağımlılıkları çek ve web için build et
RUN flutter pub get
RUN flutter build web --release --no-tree-shake-icons

# ──────────────────────────────────────────────
# Stage 2: Node.js Server
# ──────────────────────────────────────────────
FROM node:18-slim

WORKDIR /app

# Node.js bağımlılıkları
COPY frontend/package*.json ./
RUN npm install

# Server.js kopyala
COPY frontend/server.js .
COPY frontend/.env .

# Flutter build çıktısını server.js'in beklediği yere kopyala
# server.js: path.join(__dirname, '..', 'notebook_app', 'build', 'web')
#           = /notebook_app/build/web
COPY --from=flutter-builder /build/notebook_app/build/web /notebook_app/build/web

EXPOSE 3000

CMD ["node", "server.js"]
