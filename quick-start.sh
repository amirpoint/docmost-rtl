#!/bin/bash

# Quick Start Script for Docmost with Docker + nginx on Ubuntu
# Simple deployment script

echo "🚀 شروع راه‌اندازی سریع Docmost..."

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "⚠️  این اسکریپت برای اوبونتو طراحی شده است"
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "📝 ایجاد فایل .env..."
    if [ -f "env-production.example" ]; then
        cp env-production.example .env
        echo "✅ فایل .env از نمونه کپی شد"
        echo "🔧 لطفاً فایل .env را ویرایش کنید:"
        echo "   - APP_SECRET را تنظیم کنید"  
        echo "   - APP_URL را تنظیم کنید"
        echo "   - DB_PASSWORD را تنظیم کنید"
        echo ""
        echo "سپس دوباره این اسکریپت را اجرا کنید."
        exit 1
    else
        echo "❌ فایل env-production.example یافت نشد!"
        exit 1
    fi
fi

# Create required directories
echo "📁 ایجاد پوشه‌های مورد نیاز..."
mkdir -p nginx/ssl backups logs

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker نصب نیست!"
    echo "برای نصب Docker:"
    echo "curl -fsSL https://get.docker.com | sudo sh"
    echo "sudo usermod -aG docker \$USER"
    exit 1
fi

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose نصب نیست!"
    echo "sudo apt-get install docker-compose-plugin"
    exit 1
fi

echo "✅ Docker و Docker Compose موجودند"

# Start services
echo "🔄 راه‌اندازی سرویس‌ها..."
docker-compose -f docker-compose.production.yml up -d --build

echo "⏳ منتظر راه‌اندازی سرویس‌ها..."
sleep 30

# Check health
echo "🔍 بررسی سلامت..."
if curl -f -s http://localhost/health > /dev/null; then
    echo ""
    echo "✅ Docmost با موفقیت راه‌اندازی شد!"
    echo ""
    echo "🌍 آدرس: http://$(hostname -I | awk '{print $1}')"
    echo "📋 API: http://$(hostname -I | awk '{print $1}')/api"
    echo "📊 Health: http://$(hostname -I | awk '{print $1}')/health"
    echo ""
    echo "📊 وضعیت containers:"
    docker-compose -f docker-compose.production.yml ps
    echo ""
    echo "📝 دستورات مفید:"
    echo "   مشاهده لاگ‌ها: docker-compose -f docker-compose.production.yml logs -f"
    echo "   توقف: docker-compose -f docker-compose.production.yml down"
    echo "   راه‌اندازی مجدد: docker-compose -f docker-compose.production.yml restart"
else
    echo "⚠️  سرویس هنوز آماده نیست. لاگ‌ها را بررسی کنید:"
    echo "docker-compose -f docker-compose.production.yml logs"
fi 