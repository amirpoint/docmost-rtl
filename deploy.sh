#!/bin/bash

# Docmost Deployment Script for Ubuntu Server with Docker
# استفاده: ./deploy.sh [start|stop|restart|update|backup|logs]

set -e

# رنگ‌ها برای نمایش بهتر
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# متغیرها
COMPOSE_FILE="docker-compose.production.yml"
ENV_FILE=".env"
PROJECT_NAME="docmost"

# توابع کمکی
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# بررسی پیش‌نیازها
check_requirements() {
    log_info "بررسی پیش‌نیازها..."
    
    # بررسی Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker نصب نیست. لطفاً ابتدا Docker را نصب کنید."
        echo "راهنمای نصب: https://docs.docker.com/engine/install/ubuntu/"
        exit 1
    fi
    
    # بررسی Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose نصب نیست."
        echo "نصب Docker Compose: sudo apt-get install docker-compose-plugin"
        exit 1
    fi
    
    # بررسی فایل .env
    if [ ! -f "$ENV_FILE" ]; then
        log_warning "فایل .env یافت نشد. از نمونه کپی می‌کنیم..."
        if [ -f ".env.production" ]; then
            cp .env.production .env
            log_warning "لطفاً فایل .env را ویرایش کنید و مقادیر را تنظیم کنید."
            echo "nano .env"
            exit 1
        else
            log_error "فایل .env.production یافت نشد!"
            exit 1
        fi
    fi
    
    log_success "پیش‌نیازها تایید شدند"
}

# ایجاد پوشه‌های مورد نیاز
create_directories() {
    log_info "ایجاد پوشه‌های مورد نیاز..."
    
    mkdir -p nginx/ssl
    mkdir -p backups
    mkdir -p logs
    
    # تنظیم دسترسی‌ها
    chmod 755 nginx
    chmod 700 nginx/ssl
    chmod 755 backups
    chmod 755 logs
    
    log_success "پوشه‌ها ایجاد شدند"
}

# راه‌اندازی سیستم
start_system() {
    log_info "راه‌اندازی Docmost..."
    
    check_requirements
    create_directories
    
    # Build و راه‌اندازی
    log_info "Build کردن و راه‌اندازی containers..."
    docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME up -d --build
    
    # منتظر ماندن تا سرویس‌ها آماده شوند
    log_info "منتظر آماده شدن سرویس‌ها..."
    sleep 30
    
    # بررسی سلامت
    check_health
    
    log_success "Docmost با موفقیت راه‌اندازی شد!"
    show_info
}

# توقف سیستم
stop_system() {
    log_info "توقف Docmost..."
    
    docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME down
    
    log_success "Docmost متوقف شد"
}

# راه‌اندازی مجدد
restart_system() {
    log_info "راه‌اندازی مجدد Docmost..."
    
    stop_system
    sleep 5
    start_system
}

# به‌روزرسانی
update_system() {
    log_info "به‌روزرسانی Docmost..."
    
    # گرفتن آخرین تغییرات
    if [ -d ".git" ]; then
        log_info "بروزرسانی کد..."
        git pull
    fi
    
    # بیلد مجدد و راه‌اندازی
    docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME up -d --build
    
    log_success "به‌روزرسانی کامل شد"
}

# بررسی سلامت
check_health() {
    log_info "بررسی سلامت سیستم..."
    
    # بررسی containers
    if docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME ps | grep -q "Up"; then
        log_success "Containers در حال اجرا هستند"
    else
        log_error "مشکل در اجرای containers"
        return 1
    fi
    
    # بررسی دسترسی به وب
    if curl -f -s http://localhost/health > /dev/null; then
        log_success "سرویس سالم است"
    else
        log_warning "سرویس ممکن است هنوز آماده نباشد"
    fi
}

# تهیه backup
create_backup() {
    log_info "تهیه backup..."
    
    # ایجاد پوشه backup با تاریخ
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup دیتابیس
    log_info "Backup دیتابیس..."
    docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME exec -T db pg_dump -U docmost docmost > "$BACKUP_DIR/database.sql"
    
    # Backup فایل‌های storage
    log_info "Backup فایل‌های storage..."
    docker run --rm -v ${PROJECT_NAME}_app_storage:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/storage.tar.gz -C /data .
    
    # Backup تنظیمات
    cp .env "$BACKUP_DIR/"
    cp $COMPOSE_FILE "$BACKUP_DIR/"
    
    log_success "Backup ایجاد شد: $BACKUP_DIR"
}

# نمایش لاگ‌ها
show_logs() {
    local service=${1:-}
    
    if [ -n "$service" ]; then
        log_info "نمایش لاگ سرویس $service..."
        docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME logs -f "$service"
    else
        log_info "نمایش تمام لاگ‌ها..."
        docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME logs -f
    fi
}

# نمایش اطلاعات سیستم
show_info() {
    echo ""
    log_info "=== اطلاعات Docmost ==="
    echo "🌍 آدرس: http://$(hostname -I | awk '{print $1}')"
    echo "📋 API: http://$(hostname -I | awk '{print $1}')/api"
    echo "📊 Health: http://$(hostname -I | awk '{print $1}')/health"
    echo ""
    echo "📊 وضعیت containers:"
    docker-compose -f $COMPOSE_FILE --project-name $PROJECT_NAME ps
    echo ""
    echo "💾 استفاده از دیسک:"
    docker system df
    echo ""
    echo "📝 دستورات مفید:"
    echo "  نمایش لاگ‌ها: ./deploy.sh logs [service_name]"
    echo "  Backup: ./deploy.sh backup"
    echo "  بررسی سلامت: ./deploy.sh health"
    echo "  راه‌اندازی مجدد: ./deploy.sh restart"
}

# نمایش راهنما
show_help() {
    echo "استفاده: $0 [COMMAND]"
    echo ""
    echo "دستورات:"
    echo "  start     راه‌اندازی سیستم"
    echo "  stop      توقف سیستم"
    echo "  restart   راه‌اندازی مجدد"
    echo "  update    به‌روزرسانی سیستم"
    echo "  backup    تهیه backup"
    echo "  logs      نمایش لاگ‌ها"
    echo "  health    بررسی سلامت"
    echo "  info      نمایش اطلاعات"
    echo "  help      نمایش این راهنما"
}

# پردازش دستورات
case "${1:-}" in
    start)
        start_system
        ;;
    stop)
        stop_system
        ;;
    restart)
        restart_system
        ;;
    update)
        update_system
        ;;
    backup)
        create_backup
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    health)
        check_health
        ;;
    info)
        show_info
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        log_error "دستور نامعتبر: $1"
        show_help
        exit 1
        ;;
esac 