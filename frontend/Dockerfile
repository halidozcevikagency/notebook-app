FROM node:18-slim

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

# Emergent'ın server.js dosyasını çalıştırıyoruz
CMD ["node", "server.js"]
