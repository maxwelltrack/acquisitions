# Multi-stage Dockerfile for Node.js acquisitions application

# Base image with Node.js
FROM node:18-alpine AS base

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose the port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => { process.exit(1) })"

# Development stage
FROM base AS development
USER root
RUN npm ci && npm cache clean --force
USER nodejs
CMD ["npm", "run", "dev"]

# Production stage
FROM base AS production
# Add build arguments
ARG NODE_ENV=production
ARG BUILD_DATE
ARG GIT_SHA
ARG GIT_REF

# Set environment variables
ENV NODE_ENV=$NODE_ENV
ENV BUILD_DATE=$BUILD_DATE
ENV GIT_SHA=$GIT_SHA
ENV GIT_REF=$GIT_REF

# Create logs directory
RUN mkdir -p /app/logs

CMD ["npm", "start"]