# Docmost Production Deployment Script for Windows PowerShell
# این اسکریپت برای راه‌اندازی Docmost در محیط production در Windows استفاده می‌شود

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Docmost Production Deployment..." -ForegroundColor Cyan

# Check if Docker and Docker Compose are installed
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not installed. Please install Docker first." -ForegroundColor Red
    exit 1
}

if (!(Get-Command docker-compose -ErrorAction SilentlyContinue) -and !(Get-Command "docker compose" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Compose is not installed. Please install Docker Compose first." -ForegroundColor Red
    exit 1
}

# Create necessary directories
Write-Host "📁 Creating necessary directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "logs\nginx" | Out-Null
New-Item -ItemType Directory -Force -Path "logs\app" | Out-Null
New-Item -ItemType Directory -Force -Path "backups" | Out-Null
New-Item -ItemType Directory -Force -Path "data" | Out-Null

# Check if SSL certificates exist
if (!(Test-Path "ssl\certificate.crt") -or !(Test-Path "ssl\private.key")) {
    Write-Host "❌ SSL certificates not found!" -ForegroundColor Red
    Write-Host "Please place your SSL certificate as 'ssl\certificate.crt' and private key as 'ssl\private.key'" -ForegroundColor Yellow
    Write-Host "You can use your CSR.txt file to get a certificate from your CA" -ForegroundColor Yellow
    exit 1
}

# Check if environment file exists
if (!(Test-Path "production.env")) {
    Write-Host "❌ production.env file not found!" -ForegroundColor Red
    Write-Host "Please create production.env file with your configuration" -ForegroundColor Yellow
    exit 1
}

# Read and verify environment variables
Write-Host "⚙️ Checking environment variables..." -ForegroundColor Yellow
$envContent = Get-Content "production.env" | Where-Object { $_ -match "=" }
$envVars = @{}
foreach ($line in $envContent) {
    $key, $value = $line.Split("=", 2)
    $envVars[$key] = $value
}

if ($envVars["APP_SECRET"] -eq "your-super-long-random-secret-key-change-this-please") {
    Write-Host "❌ Please change the default APP_SECRET in production.env" -ForegroundColor Red
    exit 1
}

if ($envVars["DB_PASSWORD"] -eq "your-very-strong-database-password-change-this") {
    Write-Host "❌ Please change the default DB_PASSWORD in production.env" -ForegroundColor Red
    exit 1
}

# Stop existing containers
Write-Host "🛑 Stopping existing containers..." -ForegroundColor Yellow
try {
    docker-compose -f docker-compose.production.yml down --remove-orphans
} catch {
    # Ignore errors if containers don't exist
}

# Build and start services
Write-Host "🔨 Building and starting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yml --env-file production.env up -d --build

# Wait for database to be ready
Write-Host "⏳ Waiting for database to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Run database migrations
Write-Host "🗃️ Running database migrations..." -ForegroundColor Yellow
docker exec docmost-app pnpm --filter server migration:latest

# Check service health
Write-Host "🔍 Checking service health..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$dockerPsOutput = docker ps

if ($dockerPsOutput -match "docmost-nginx.*Up") {
    Write-Host "✅ Nginx is running" -ForegroundColor Green
} else {
    Write-Host "❌ Nginx failed to start" -ForegroundColor Red
}

if ($dockerPsOutput -match "docmost-app.*Up") {
    Write-Host "✅ Docmost app is running" -ForegroundColor Green
} else {
    Write-Host "❌ Docmost app failed to start" -ForegroundColor Red
}

if ($dockerPsOutput -match "docmost-postgres.*Up") {
    Write-Host "✅ PostgreSQL is running" -ForegroundColor Green
} else {
    Write-Host "❌ PostgreSQL failed to start" -ForegroundColor Red
}

if ($dockerPsOutput -match "docmost-redis.*Up") {
    Write-Host "✅ Redis is running" -ForegroundColor Green
} else {
    Write-Host "❌ Redis failed to start" -ForegroundColor Red
}

# Display final information
Write-Host ""
Write-Host "🎉 Deployment completed!" -ForegroundColor Green
Write-Host "Your Docmost instance should be available at: https://smartx.ir" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor Yellow
Write-Host "  View logs: docker-compose -f docker-compose.production.yml logs -f"
Write-Host "  Stop services: docker-compose -f docker-compose.production.yml down"
Write-Host "  Restart services: docker-compose -f docker-compose.production.yml restart"
Write-Host "  Update application: .\scripts\update.ps1"
Write-Host ""
Write-Host "💾 Backup commands:" -ForegroundColor Yellow
Write-Host "  Backup database: .\scripts\backup.ps1" 