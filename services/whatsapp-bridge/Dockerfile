FROM node:22-alpine AS build
RUN apk add --no-cache git python3 make g++
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:22-alpine
RUN apk add --no-cache curl
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist

RUN mkdir -p /data/auth
VOLUME ["/data/auth"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD sh -c 'test $(( $(date +%s) - $(date -r /tmp/healthy +%s 2>/dev/null || echo 0) )) -lt 180 || curl -f http://localhost:8766/health'

CMD ["node", "dist/index.js"]
