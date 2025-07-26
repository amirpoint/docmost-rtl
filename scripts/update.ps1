# Docmost Update Script for Windows PowerShell

$ErrorActionPreference = "Stop"

Write-Host "🔄 Starting Docmost update process..." -ForegroundColor Yellow

# Create backup before update
Write-Host "📦 Creating backup before update..." -ForegroundColor Yellow
& ".\scripts\backup.ps1"

# Pull latest changes
Write-Host "📥 Pulling latest changes..." -ForegroundColor Yellow
git pull origin main

# Rebuild and restart services
Write-Host "🔨 Rebuilding services..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yml --env-file production.env build --no-cache

Write-Host "🔄 Restarting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yml --env-file production.env up -d

# Wait for database to be ready
Write-Host "⏳ Waiting for database to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Run database migrations
Write-Host "🗃️ Running database migrations..." -ForegroundColor Yellow
docker exec docmost-app pnpm --filter server migration:latest

Write-Host "✅ Update completed successfully!" -ForegroundColor Green
Write-Host "🎉 Your Docmost instance has been updated and is ready to use." -ForegroundColor Green 