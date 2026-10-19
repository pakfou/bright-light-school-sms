# Unified Fullstack Production Image (Node.js API + Flutter Web)
FROM node:20-alpine

WORKDIR /app

# Install backend dependencies
COPY backend/package*.json ./
RUN npm install --omit=dev

# Copy backend source code
COPY backend/ ./

# Copy compiled Flutter web build into public/app if build exists
COPY build/web/ ./public/app/

# Environment Configuration
ENV NODE_ENV=production
ENV PORT=8080

EXPOSE 8080

# Health check probe for Cloud Run, Render, and Docker
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-8080}/health || exit 1

CMD ["node", "server.js"]
