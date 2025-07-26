#!/bin/bash

# Docmost Production Deployment Script
# این اسکریپت برای راه‌اندازی Docmost در محیط production استفاده می‌شود

set -e

echo "🚀 Starting Docmost Production Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
mkdir -p logs/nginx
mkdir -p logs/app
mkdir -p backups
mkdir -p data

# Check if SSL certificates exist
if [ ! -f "ssl/certificate.crt" ] || [ ! -f "ssl/private.key" ]; then
    echo -e "${RED}❌ SSL certificates not found!${NC}"
    echo -e "${YELLOW}Please place your SSL certificate as 'ssl/certificate.crt' and private key as 'ssl/private.key'${NC}"
    echo -e "${YELLOW}You can use your CSR.txt file to get a certificate from your CA${NC}"
    exit 1
fi

# Check if environment file exists
if [ ! -f "production.env" ]; then
    echo -e "${RED}❌ production.env file not found!${NC}"
    echo -e "${YELLOW}Please create production.env file with your configuration${NC}"
    exit 1
fi

# Verify environment variables
echo -e "${YELLOW}⚙️  Checking environment variables...${NC}"
source production.env

if [ "$APP_SECRET" = "your-super-long-random-secret-key-change-this-please" ]; then
    echo -e "${RED}❌ Please change the default APP_SECRET in production.env${NC}"
    exit 1
fi

if [ "$DB_PASSWORD" = "your-very-strong-database-password-change-this" ]; then
    echo -e "${RED}❌ Please change the default DB_PASSWORD in production.env${NC}"
    exit 1
fi

# Stop existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker-compose -f docker-compose.production.yml down --remove-orphans || true

# Build and start services
echo -e "${YELLOW}🔨 Building and starting services...${NC}"
docker-compose -f docker-compose.production.yml --env-file production.env up -d --build

# Wait for database to be ready
echo -e "${YELLOW}⏳ Waiting for database to be ready...${NC}"
sleep 10

# Run database migrations
echo -e "${YELLOW}🗃️  Running database migrations...${NC}"
docker exec docmost-app pnpm --filter server migration:latest

# Check service health
echo -e "${YELLOW}🔍 Checking service health...${NC}"
sleep 5

if docker ps | grep -q "docmost-nginx.*Up"; then
    echo -e "${GREEN}✅ Nginx is running${NC}"
else
    echo -e "${RED}❌ Nginx failed to start${NC}"
fi

if docker ps | grep -q "docmost-app.*Up"; then
    echo -e "${GREEN}✅ Docmost app is running${NC}"
else
    echo -e "${RED}❌ Docmost app failed to start${NC}"
fi

if docker ps | grep -q "docmost-postgres.*Up"; then
    echo -e "${GREEN}✅ PostgreSQL is running${NC}"
else
    echo -e "${RED}❌ PostgreSQL failed to start${NC}"
fi

if docker ps | grep -q "docmost-redis.*Up"; then
    echo -e "${GREEN}✅ Redis is running${NC}"
else
    echo -e "${RED}❌ Redis failed to start${NC}"
fi

# Display final information
echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo -e "${GREEN}Your Docmost instance should be available at: https://smartx.ir${NC}"
echo ""
echo -e "${YELLOW}📋 Useful commands:${NC}"
echo "  View logs: docker-compose -f docker-compose.production.yml logs -f"
echo "  Stop services: docker-compose -f docker-compose.production.yml down"
echo "  Restart services: docker-compose -f docker-compose.production.yml restart"
echo "  Update application: ./scripts/update.sh"
echo ""
echo -e "${YELLOW}💾 Backup commands:${NC}"
echo "  Backup database: ./scripts/backup.sh"
echo "  Restore database: ./scripts/restore.sh <backup-file>" 