#!/bin/bash

# توقف Docmost

echo "⏹️  توقف Docmost..."

# توقف سرور
if [ -f "server.pid" ]; then
    SERVER_PID=$(cat server.pid)
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        echo "🛑 توقف سرور (PID: $SERVER_PID)..."
        kill $SERVER_PID
        sleep 3
        
        # اگر هنوز اجرا است، force kill
        if ps -p $SERVER_PID > /dev/null 2>&1; then
            echo "⚠️  Force killing server..."
            kill -9 $SERVER_PID
        fi
    fi
    rm -f server.pid
fi

# توقف nginx (اختیاری - معمولاً nginx باقی می‌ماند)
read -p "آیا می‌خواهید nginx را نیز متوقف کنید؟ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🌐 توقف nginx..."
    sudo systemctl stop nginx
fi

# توقف دیتابیس و redis
read -p "آیا می‌خواهید دیتابیس و Redis را نیز متوقف کنید؟ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🐘 توقف دیتابیس و Redis..."
    docker-compose down
fi

echo "✅ Docmost متوقف شد!" 