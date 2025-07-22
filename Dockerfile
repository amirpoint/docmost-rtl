FROM node:22-alpine AS base
LABEL org.opencontainers.image.source="https://github.com/docmost/docmost"

FROM base AS builder

WORKDIR /app

# Copy package files first for better cache efficiency
COPY package.json pnpm*.yaml ./
COPY apps/server/package.json ./apps/server/
COPY apps/client/package.json ./apps/client/
COPY packages/editor-ext/package.json ./packages/editor-ext/

RUN npm install -g pnpm@10.4.0

# Copy patches before install
COPY patches ./patches

# Install dependencies including dev dependencies for build (no frozen lockfile for build mode)
RUN pnpm install --no-frozen-lockfile

# Install TypeScript globally for build
RUN npm install -g typescript

# Copy source code
COPY . .

# Build the application
RUN pnpm build

FROM base AS installer

RUN apk add --no-cache curl bash

WORKDIR /app

# Copy built applications
COPY --from=builder /app/apps/server/dist /app/apps/server/dist
COPY --from=builder /app/apps/client/dist /app/apps/client/dist
COPY --from=builder /app/packages/editor-ext/dist /app/packages/editor-ext/dist

# Copy only server package.json (we only need server for production)
COPY --from=builder /app/apps/server/package.json /app/apps/server/package.json
COPY --from=builder /app/packages/editor-ext/package.json /app/packages/editor-ext/package.json
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/pnpm*.yaml /app/

RUN npm install -g pnpm@10.4.0

# Create minimal package.json without patches for production
RUN echo '{"name":"docmost","private":true,"scripts":{"start":"pnpm --filter ./apps/server run start:prod"},"dependencies":{"@docmost/editor-ext":"workspace:*"},"workspaces":{"packages":["apps/server","packages/editor-ext"]}}' > package.json

RUN chown -R node:node /app

USER node

# Install only server production dependencies
RUN cd apps/server && pnpm install --prod --no-frozen-lockfile

RUN mkdir -p /app/data/storage

VOLUME ["/app/data/storage"]

EXPOSE 3000

CMD ["pnpm", "start"]
