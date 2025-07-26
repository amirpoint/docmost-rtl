#!/bin/bash

# Docmost Update Script

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Starting Docmost update process...${NC}"

# Create backup before update
echo -e "${YELLOW}📦 Creating backup before update...${NC}"
./scripts/backup.sh

# Pull latest changes
echo -e "${YELLOW}📥 Pulling latest changes...${NC}"
git pull origin main

# Rebuild and restart services
echo -e "${YELLOW}🔨 Rebuilding services...${NC}"
docker-compose -f docker-compose.production.yml --env-file production.env build --no-cache

echo -e "${YELLOW}🔄 Restarting services...${NC}"
docker-compose -f docker-compose.production.yml --env-file production.env up -d

# Wait for database to be ready
echo -e "${YELLOW}⏳ Waiting for database to be ready...${NC}"
sleep 10

# Run database migrations
echo -e "${YELLOW}🗃️  Running database migrations...${NC}"
docker exec docmost-app pnpm --filter server migration:latest

echo -e "${GREEN}✅ Update completed successfully!${NC}"
echo -e "${GREEN}🎉 Your Docmost instance has been updated and is ready to use.${NC}" 