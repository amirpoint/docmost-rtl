FROM node:22-alpine AS base
LABEL org.opencontainers.image.source="https://github.com/docmost/docmost"

FROM base AS builder

WORKDIR /app

# Install pnpm and TypeScript globally (rarely change, good to cache)
RUN npm install -g pnpm@10.4.0 typescript

# Copy package files first for better cache efficiency
COPY package.json pnpm*.yaml ./
COPY apps/server/package.json ./apps/server/
COPY apps/client/package.json ./apps/client/
COPY packages/editor-ext/package.json ./packages/editor-ext/

# Copy patches before install
COPY patches ./patches

# Install dependencies including dev dependencies for build (no frozen lockfile for build mode)
RUN pnpm install --no-frozen-lockfile

# Copy source code (excluding .env files via .dockerignore)
COPY . .

# Build the application
RUN pnpm build

FROM base AS installer

RUN apk add --no-cache curl bash

# Create app directory and set permissions
RUN mkdir -p /app/data/storage && chown -R node:node /app

WORKDIR /app

# Set user to node BEFORE copying files
USER node

# Copy built applications and their dependencies (with chown in COPY)
COPY --from=builder --chown=node:node /app/apps/server/dist /app/apps/server/dist
COPY --from=builder --chown=node:node /app/apps/client/dist /app/apps/client/dist
COPY --from=builder --chown=node:node /app/packages/editor-ext/dist /app/packages/editor-ext/dist

# Copy node_modules from builder (already contains production dependencies)
COPY --from=builder --chown=node:node /app/node_modules /app/node_modules
COPY --from=builder --chown=node:node /app/apps/server/node_modules /app/apps/server/node_modules
COPY --from=builder --chown=node:node /app/packages/editor-ext/node_modules /app/packages/editor-ext/node_modules

# Copy package files
COPY --from=builder --chown=node:node /app/apps/server/package.json /app/apps/server/package.json
COPY --from=builder --chown=node:node /app/packages/editor-ext/package.json /app/packages/editor-ext/package.json
COPY --from=builder --chown=node:node /app/package.json /app/package.json
COPY --from=builder --chown=node:node /app/pnpm*.yaml /app/

# Switch back to root temporarily to install pnpm
USER root
RUN npm install -g pnpm@10.4.0
USER node

# Create minimal package.json for production
RUN echo '{"name":"docmost","private":true,"scripts":{"start":"node ./apps/server/dist/main"},"dependencies":{"@docmost/editor-ext":"workspace:*"},"workspaces":{"packages":["apps/server","packages/editor-ext"]}}' > /tmp/package.json && mv /tmp/package.json /app/package.json

VOLUME ["/app/data/storage"]

EXPOSE 3000

CMD ["pnpm", "start"]
