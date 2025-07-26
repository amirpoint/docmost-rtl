# Docmost با nginx راه‌اندازی - Windows PowerShell Script

Write-Host "🚀 راه‌اندازی Docmost با nginx..." -ForegroundColor Green

# بررسی وجود فایل‌های بیلد شده
if (-not (Test-Path "apps\client\dist")) {
    Write-Host "❌ خطا: فایل‌های کلاینت بیلد نشده‌اند. ابتدا 'pnpm client:build' را اجرا کنید" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "apps\server\dist")) {
    Write-Host "❌ خطا: فایل‌های سرور بیلد نشده‌اند. ابتدا 'pnpm server:build' را اجرا کنید" -ForegroundColor Red
    exit 1
}

# بررسی وجود nginx
try {
    nginx -v | Out-Null
    Write-Host "✅ nginx یافت شد" -ForegroundColor Green
} catch {
    Write-Host "❌ خطا: nginx نصب نیست" -ForegroundColor Red
    Write-Host "برای نصب nginx:" -ForegroundColor Yellow
    Write-Host "1. از https://nginx.org/en/download.html دانلود کنید" -ForegroundColor Yellow
    Write-Host "2. یا از Chocolatey: choco install nginx" -ForegroundColor Yellow
    Write-Host "3. یا از Scoop: scoop install nginx" -ForegroundColor Yellow
    exit 1
}

# تنظیم مسیر پروژه در nginx config
$ProjectPath = (Get-Location).Path -replace '\\', '/'
Write-Host "📁 مسیر پروژه: $ProjectPath" -ForegroundColor Cyan

# آماده‌سازی کانفیگوریشن nginx
$nginxConfig = Get-Content "nginx\nginx.conf" -Raw
$nginxConfig = $nginxConfig -replace "D:/smart-development/docmost", $ProjectPath
$nginxConfig | Out-File "nginx\nginx.conf" -Encoding UTF8

Write-Host "📝 کانفیگوریشن nginx به‌روزرسانی شد" -ForegroundColor Green

# بررسی کانفیگوریشن nginx
Write-Host "🔍 بررسی کانفیگوریشن nginx..." -ForegroundColor Cyan
try {
    nginx -t
    Write-Host "✅ کانفیگوریشن nginx صحیح است" -ForegroundColor Green
} catch {
    Write-Host "❌ خطا در کانفیگوریشن nginx" -ForegroundColor Red
    exit 1
}

# راه‌اندازی دیتابیس و redis
Write-Host "🐘 راه‌اندازی دیتابیس و Redis..." -ForegroundColor Cyan
docker-compose up -d db redis

# منتظر راه‌اندازی دیتابیس
Write-Host "⏳ منتظر راه‌اندازی دیتابیس..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# اجرای migration ها
Write-Host "🔄 اجرای migrations..." -ForegroundColor Cyan
Set-Location "apps\server"
try {
    pnpm migration:latest
    Write-Host "✅ Migrations با موفقیت اجرا شد" -ForegroundColor Green
} catch {
    Write-Host "⚠️  خطا در اجرای migrations - ادامه می‌دهیم..." -ForegroundColor Yellow
}
Set-Location "..\..\"

# راه‌اندازی سرور در پس‌زمینه
Write-Host "🚀 راه‌اندازی سرور..." -ForegroundColor Cyan
Set-Location "apps\server"

# بررسی اینکه آیا سرور قبلاً اجرا است
$existingProcess = Get-Process | Where-Object { $_.ProcessName -eq "node" -and $_.MainWindowTitle -like "*start:prod*" }
if ($existingProcess) {
    Write-Host "⚠️  سرور قبلاً در حال اجرا است. متوقف می‌کنیم..." -ForegroundColor Yellow
    $existingProcess | Stop-Process -Force
    Start-Sleep -Seconds 3
}

# راه‌اندازی سرور جدید
$serverJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    pnpm start:prod
}

Write-Host "✅ سرور شروع شد (Job ID: $($serverJob.Id))" -ForegroundColor Green
$serverJob.Id | Out-File "..\..\server.job" -Encoding UTF8

Set-Location "..\..\"

# راه‌اندازی nginx
Write-Host "🌐 راه‌اندازی nginx..." -ForegroundColor Cyan

# بررسی اینکه آیا nginx اجرا است
$nginxProcess = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
if ($nginxProcess) {
    Write-Host "🔄 nginx در حال اجرا است، reload می‌کنیم..." -ForegroundColor Yellow
    nginx -s reload
} else {
    Write-Host "🌐 راه‌اندازی nginx..." -ForegroundColor Cyan
    Start-Process nginx -WindowStyle Hidden
}

# منتظر ماندن تا سرویس‌ها آماده شوند
Write-Host "⏳ منتظر آماده شدن سرویس‌ها..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "✅ Docmost با موفقیت راه‌اندازی شد!" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host ""
Write-Host "🌍 آدرس: http://localhost" -ForegroundColor Cyan
Write-Host "📋 API آدرس: http://localhost/api" -ForegroundColor Cyan
Write-Host "📊 Health Check: http://localhost/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 لاگ‌ها:" -ForegroundColor White
Write-Host "   سرور: logs\server.log" -ForegroundColor Gray
Write-Host "   nginx: مسیر نصب nginx\logs\" -ForegroundColor Gray
Write-Host ""
Write-Host "⏹️  برای توقف: .\stop-docmost.ps1" -ForegroundColor Red

# تست سلامت
Write-Host "🔍 تست سلامت سرویس..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost/health" -TimeoutSec 10 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ سرویس سالم است و آماده استفاده!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  سرویس ممکن است هنوز آماده نباشد. لطفاً چند دقیقه منتظر بمانید." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  نتوانستیم به سرویس متصل شویم. لطفاً لاگ‌ها را بررسی کنید." -ForegroundColor Yellow
} 