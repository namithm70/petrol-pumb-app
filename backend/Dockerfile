FROM node:20-alpine

ENV NODE_ENV=production
WORKDIR /app

# Install curl for healthchecks and dumb-init for PID 1 signal handling
RUN apk add --no-cache curl dumb-init

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://127.0.0.1:3001/api/health || exit 1

CMD ["dumb-init", "node", "src/index.js"]
