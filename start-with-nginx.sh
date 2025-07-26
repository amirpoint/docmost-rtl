#!/bin/bash

# Docmost با nginx راه‌اندازی

echo "🚀 راه‌اندازی Docmost با nginx..."

# بررسی وجود فایل‌های بیلد شده
if [ ! -d "apps/client/dist" ]; then
    echo "❌ خطا: فایل‌های کلاینت بیلد نشده‌اند. ابتدا 'pnpm client:build' را اجرا کنید"
    exit 1
fi

if [ ! -d "apps/server/dist" ]; then
    echo "❌ خطا: فایل‌های سرور بیلد نشده‌اند. ابتدا 'pnpm server:build' را اجرا کنید"
    exit 1
fi

# بررسی وجود nginx
if ! command -v nginx &> /dev/null; then
    echo "❌ خطا: nginx نصب نیست"
    echo "برای نصب nginx:"
    echo "Ubuntu/Debian: sudo apt install nginx"
    echo "CentOS/RHEL: sudo yum install nginx"
    echo "macOS: brew install nginx"
    exit 1
fi

# تنظیم مسیر پروژه در nginx config
PROJECT_PATH=$(pwd)
sed -i.bak "s|/path/to/your/project|$PROJECT_PATH|g" nginx/nginx.conf

echo "📁 مسیر پروژه در nginx تنظیم شد: $PROJECT_PATH"

# کپی کردن کانفیگوریشن nginx
sudo cp nginx/nginx.conf /etc/nginx/sites-available/docmost
sudo ln -sf /etc/nginx/sites-available/docmost /etc/nginx/sites-enabled/docmost

# حذف default site
sudo rm -f /etc/nginx/sites-enabled/default

# تست کانفیگوریشن nginx
if ! sudo nginx -t; then
    echo "❌ خطا در کانفیگوریشن nginx"
    exit 1
fi

# راه‌اندازی دیتابیس و redis
echo "🐘 راه‌اندازی دیتابیس و Redis..."
docker-compose up -d db redis

# منتظر راه‌اندازی دیتابیس
sleep 5

# اجرای migration ها
echo "🔄 اجرای migrations..."
cd apps/server
pnpm migration:latest
cd ../..

# راه‌اندازی سرور در پس‌زمینه
echo "🚀 راه‌اندازی سرور..."
cd apps/server
nohup pnpm start:prod > ../../logs/server.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > ../../server.pid
cd ../..

# راه‌اندازی nginx
echo "🌐 راه‌اندازی nginx..."
sudo systemctl reload nginx

echo "✅ Docmost با موفقیت راه‌اندازی شد!"
echo ""
echo "🌍 آدرس: http://localhost"
echo "📋 API آدرس: http://localhost/api"
echo "📊 Health Check: http://localhost/health"
echo ""
echo "📝 لاگ‌ها:"
echo "   سرور: logs/server.log"
echo "   nginx: /var/log/nginx/docmost_*.log"
echo ""
echo "⏹️  برای توقف: ./stop-docmost.sh" 