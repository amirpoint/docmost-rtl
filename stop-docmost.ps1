# توقف Docmost - Windows PowerShell Script

Write-Host "⏹️  توقف Docmost..." -ForegroundColor Yellow

# توقف سرور Node.js
Write-Host "🛑 توقف سرور..." -ForegroundColor Cyan

# بررسی وجود Job ID
if (Test-Path "server.job") {
    $jobId = Get-Content "server.job" -Raw
    $jobId = $jobId.Trim()
    
    if ($jobId) {
        try {
            $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
            if ($job) {
                Stop-Job -Id $jobId
                Remove-Job -Id $jobId
                Write-Host "✅ سرور Job متوقف شد" -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️  Job پیدا نشد، سعی می‌کنیم پردازش‌های Node.js را پیدا کنیم..." -ForegroundColor Yellow
        }
    }
    
    Remove-Item "server.job" -ErrorAction SilentlyContinue
}

# توقف تمام پردازش‌های Node.js مرتبط با Docmost
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "🔍 پیدا کردن و توقف پردازش‌های Node.js..." -ForegroundColor Cyan
    $nodeProcesses | ForEach-Object {
        try {
            $_.Kill()
            Write-Host "✅ پردازش Node.js متوقف شد (PID: $($_.Id))" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  نتوانستیم پردازش $($_.Id) را متوقف کنیم" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "✅ هیچ پردازش Node.js فعالی پیدا نشد" -ForegroundColor Green
}

# سوال برای توقف nginx
$stopNginx = Read-Host "آیا می‌خواهید nginx را نیز متوقف کنید؟ (y/N)"
if ($stopNginx -eq "y" -or $stopNginx -eq "Y") {
    Write-Host "🌐 توقف nginx..." -ForegroundColor Cyan
    
    try {
        nginx -s quit
        
        # منتظر ماندن تا nginx متوقف شود
        Start-Sleep -Seconds 3
        
        # بررسی اینکه آیا nginx هنوز اجرا است
        $nginxProcess = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
        if ($nginxProcess) {
            Write-Host "⚠️  nginx به روش عادی متوقف نشد، force kill می‌کنیم..." -ForegroundColor Yellow
            $nginxProcess | Stop-Process -Force
        }
        
        Write-Host "✅ nginx متوقف شد" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  خطا در توقف nginx: $($_.Exception.Message)" -ForegroundColor Yellow
        
        # تلاش برای force kill
        $nginxProcess = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
        if ($nginxProcess) {
            $nginxProcess | Stop-Process -Force
            Write-Host "✅ nginx با force متوقف شد" -ForegroundColor Green
        }
    }
} else {
    Write-Host "ℹ️  nginx همچنان در حال اجرا است" -ForegroundColor Cyan
}

# سوال برای توقف دیتابیس
$stopDatabase = Read-Host "آیا می‌خواهید دیتابیس و Redis را نیز متوقف کنید؟ (y/N)"
if ($stopDatabase -eq "y" -or $stopDatabase -eq "Y") {
    Write-Host "🐘 توقف دیتابیس و Redis..." -ForegroundColor Cyan
    
    try {
        docker-compose down
        Write-Host "✅ دیتابیس و Redis متوقف شدند" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  خطا در توقف دیتابیس: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  دیتابیس و Redis همچنان در حال اجرا هستند" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "✅ Docmost متوقف شد!" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host ""

# نمایش وضعیت نهایی
Write-Host "📊 وضعیت نهایی:" -ForegroundColor White
Write-Host "   Node.js processes: " -NoNewline -ForegroundColor Gray
$remainingNode = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($remainingNode) {
    Write-Host "$($remainingNode.Count) در حال اجرا" -ForegroundColor Yellow
} else {
    Write-Host "متوقف شده" -ForegroundColor Green
}

Write-Host "   nginx processes: " -NoNewline -ForegroundColor Gray
$remainingNginx = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
if ($remainingNginx) {
    Write-Host "$($remainingNginx.Count) در حال اجرا" -ForegroundColor Yellow
} else {
    Write-Host "متوقف شده" -ForegroundColor Green
}

# بررسی Docker containers
try {
    $dockerContainers = docker ps --filter "name=docmost" --format "table {{.Names}}\t{{.Status}}" 2>$null
    if ($dockerContainers -and $dockerContainers.Length -gt 1) {
        Write-Host "   Docker containers:" -ForegroundColor Gray
        $dockerContainers | Select-Object -Skip 1 | ForEach-Object {
            Write-Host "     $_" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   Docker containers: متوقف شده" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Docker containers: نامشخص" -ForegroundColor Gray
} 