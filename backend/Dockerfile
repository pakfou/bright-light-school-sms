# Multi-stage / lightweight Node.js container
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install dependencies first (layer caching)
COPY package*.json ./
RUN npm install --omit=dev

# Copy server code and public assets
COPY . .

# Set default environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose default port
EXPOSE 5000

# Health check probe
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-5000}/health || exit 1

# Start Node.js backend
CMD ["node", "server.js"]
