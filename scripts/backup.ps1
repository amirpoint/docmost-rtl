# Docmost Database Backup Script for Windows PowerShell

$ErrorActionPreference = "Stop"

# Check if environment file exists
if (!(Test-Path "production.env")) {
    Write-Host "❌ production.env file not found!" -ForegroundColor Red
    exit 1
}

# Create backup directory
$backupDir = ".\backups"
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
}

# Generate backup filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$backupDir\docmost_backup_$timestamp.sql"

Write-Host "📦 Creating database backup..." -ForegroundColor Yellow

# Create database backup
try {
    docker exec docmost-postgres pg_dump -U docmost -d docmost | Out-File -Encoding UTF8 $backupFile
    
    Write-Host "✅ Database backup created successfully: $backupFile" -ForegroundColor Green
    
    # Compress the backup using built-in Windows compression
    $backupFileGz = "$backupFile.gz"
    Compress-Archive -Path $backupFile -DestinationPath $backupFileGz -Force
    Remove-Item $backupFile # Remove uncompressed file
    
    Write-Host "✅ Backup compressed: $backupFileGz" -ForegroundColor Green
    
    # Calculate file size
    $backupSize = (Get-Item $backupFileGz).Length
    $backupSizeFormatted = "{0:N2} MB" -f ($backupSize / 1MB)
    Write-Host "📊 Backup size: $backupSizeFormatted" -ForegroundColor Green
    
    # Clean up old backups (keep last 7 days)
    Write-Host "🧹 Cleaning up old backups..." -ForegroundColor Yellow
    $oldBackups = Get-ChildItem -Path $backupDir -Name "docmost_backup_*.sql.zip" | 
                  Where-Object { (Get-Item "$backupDir\$_").LastWriteTime -lt (Get-Date).AddDays(-7) }
    
    foreach ($oldBackup in $oldBackups) {
        Remove-Item "$backupDir\$oldBackup" -Force
    }
    
    Write-Host "🎉 Backup process completed!" -ForegroundColor Green
} catch {
    Write-Host "❌ Backup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 