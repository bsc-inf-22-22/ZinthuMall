FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci
RUN npm install -g @nestjs/cli

COPY . .

RUN npx prisma generate
RUN npm run build

EXPOSE 3001

CMD ["node", "dist/main.js"]
