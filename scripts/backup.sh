#!/bin/bash

# Docmost Database Backup Script

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load environment variables
if [ -f "production.env" ]; then
    source production.env
else
    echo -e "${RED}❌ production.env file not found!${NC}"
    exit 1
fi

# Create backup directory
BACKUP_DIR="./backups"
mkdir -p $BACKUP_DIR

# Generate backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/docmost_backup_$TIMESTAMP.sql"

echo -e "${YELLOW}📦 Creating database backup...${NC}"

# Create database backup
docker exec docmost-postgres pg_dump -U docmost -d docmost > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database backup created successfully: $BACKUP_FILE${NC}"
    
    # Compress the backup
    gzip "$BACKUP_FILE"
    echo -e "${GREEN}✅ Backup compressed: ${BACKUP_FILE}.gz${NC}"
    
    # Calculate file size
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
    echo -e "${GREEN}📊 Backup size: $BACKUP_SIZE${NC}"
    
    # Clean up old backups (keep last 7 days)
    echo -e "${YELLOW}🧹 Cleaning up old backups...${NC}"
    find $BACKUP_DIR -name "docmost_backup_*.sql.gz" -mtime +7 -delete
    
    echo -e "${GREEN}🎉 Backup process completed!${NC}"
else
    echo -e "${RED}❌ Backup failed!${NC}"
    exit 1
fi 