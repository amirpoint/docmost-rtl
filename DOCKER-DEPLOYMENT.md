# راهنمای کامل Deploy کردن Docmost در سرور اوبونتو با Docker + nginx

## معماری راه‌حل

```
Internet → nginx (Port 80/443) → Docmost App (Port 3000) → PostgreSQL + Redis
          ↓
     Static Files (React SPA)
```

## پیش‌نیازها

### 1. سرور اوبونتو
- Ubuntu 20.04 یا بالاتر
- حداقل 2GB RAM
- حداقل 20GB فضای دیسک
- دسترسی root یا sudo

### 2. نصب Docker
```bash
# به‌روزرسانی سیستم
sudo apt update && sudo apt upgrade -y

# نصب پیش‌نیازها
sudo apt install -y ca-certificates curl gnupg lsb-release

# اضافه کردن GPG key رسمی Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# اضافه کردن repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# نصب Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# اضافه کردن کاربر به گروه docker
sudo usermod -aG docker $USER

# تست Docker
sudo systemctl enable docker
sudo systemctl start docker
```

### 3. نصب Docker Compose
```bash
# Docker Compose V2 همراه با Docker نصب می‌شود
# برای نسخه standalone:
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## راه‌اندازی

### مرحله 1: آماده‌سازی پروژه

```bash
# کلون کردن پروژه
git clone https://github.com/docmost/docmost.git
cd docmost

# یا آپلود فایل‌های بیلد شده
# اگر فایل‌هایتان را از قبل بیلد کرده‌اید
```

### مرحله 2: تنظیم متغیرهای محیطی

```bash
# کپی کردن فایل نمونه
cp env-production.example .env

# ویرایش تنظیمات
nano .env
```

**نکات مهم برای .env:**
```env
# کلید امنیتی قوی (حداقل 32 کاراکتر)
APP_SECRET=your-very-long-secret-key-here-min-32-chars

# دامنه سرور (بدون http://)
APP_URL=http://your-domain.com

# رمز عبور قوی دیتابیس
DB_PASSWORD=your-strong-database-password
```

### مرحله 3: راه‌اندازی با اسکریپت خودکار

```bash
# اجازه اجرا دادن به اسکریپت
chmod +x deploy.sh

# راه‌اندازی سیستم
./deploy.sh start
```

### مرحله 4: بررسی وضعیت

```bash
# بررسی containers
./deploy.sh info

# مشاهده لاگ‌ها
./deploy.sh logs

# بررسی سلامت
./deploy.sh health
```

## دستورات مدیریت

```bash
# راه‌اندازی
./deploy.sh start

# توقف
./deploy.sh stop

# راه‌اندازی مجدد
./deploy.sh restart

# به‌روزرسانی
./deploy.sh update

# تهیه backup
./deploy.sh backup

# مشاهده لاگ‌ها
./deploy.sh logs [service_name]

# بررسی سلامت
./deploy.sh health

# نمایش اطلاعات
./deploy.sh info
```

## راه‌اندازی دستی (اختیاری)

اگر می‌خواهید بدون اسکریپت راه‌اندازی کنید:

```bash
# ایجاد پوشه‌های مورد نیاز
mkdir -p nginx/ssl backups logs

# راه‌اندازی
docker-compose -f docker-compose.production.yml up -d --build

# بررسی وضعیت
docker-compose -f docker-compose.production.yml ps

# مشاهده لاگ‌ها
docker-compose -f docker-compose.production.yml logs -f
```

## تنظیم Domain و SSL

### برای دامنه:
1. فایل `.env` را ویرایش کنید:
   ```env
   APP_URL=http://yourdomain.com
   ```

2. فایل `nginx/nginx-docker.conf` را ویرایش کنید:
   ```nginx
   server_name yourdomain.com;
   ```

### برای SSL (Let's Encrypt):
```bash
# نصب Certbot
sudo apt install snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot

# ایجاد certificate
sudo certbot certonly --standalone -d yourdomain.com

# کپی certificate ها
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/ssl/private.key
sudo chown -R $USER:$USER nginx/ssl/

# فعال کردن HTTPS در nginx config
# خطوط HTTPS server را uncomment کنید
```

## Backup و Restore

### تهیه Backup خودکار:
```bash
# Backup دستی
./deploy.sh backup

# تنظیم Backup خودکار
crontab -e

# اضافه کردن خط زیر برای backup روزانه در ساعت 2 صبح
0 2 * * * cd /path/to/docmost && ./deploy.sh backup
```

### Restore از Backup:
```bash
# توقف سیستم
./deploy.sh stop

# Restore دیتابیس
docker-compose -f docker-compose.production.yml exec -T db psql -U docmost -d docmost < backups/YYYYMMDD_HHMMSS/database.sql

# Restore فایل‌ها
docker run --rm -v docmost_app_storage:/data -v $(pwd)/backups/YYYYMMDD_HHMMSS:/backup alpine tar xzf /backup/storage.tar.gz -C /data

# راه‌اندازی مجدد
./deploy.sh start
```

## نگهداری و Monitoring

### بررسی Resource ها:
```bash
# استفاده از RAM و CPU
docker stats

# استفاده از دیسک
docker system df

# پاک کردن فایل‌های اضافی
docker system prune -f
```

### مدیریت لاگ‌ها:
```bash
# محدود کردن سایز لاگ‌ها
echo '{"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"}}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

## عیب‌یابی

### مشکلات رایج:

**1. Container ها راه نمی‌اندازند:**
```bash
# بررسی لاگ‌ها
./deploy.sh logs

# بررسی فضای دیسک
df -h

# بررسی RAM
free -h
```

**2. دسترسی به دیتابیس:**
```bash
# اتصال مستقیم به دیتابیس
docker-compose -f docker-compose.production.yml exec db psql -U docmost -d docmost
```

**3. مشکل nginx:**
```bash
# تست کانفیگوریشن nginx
docker-compose -f docker-compose.production.yml exec nginx nginx -t

# مشاهده لاگ nginx
./deploy.sh logs nginx
```

**4. فایل‌های استاتیک لود نمی‌شوند:**
```bash
# بررسی volume ها
docker volume ls
docker volume inspect docmost_static_files
```

## نکات امنیتی

1. **Firewall:**
   ```bash
   sudo ufw enable
   sudo ufw allow 22    # SSH
   sudo ufw allow 80    # HTTP
   sudo ufw allow 443   # HTTPS
   ```

2. **Updates منظم:**
   ```bash
   # به‌روزرسانی سیستم‌عامل
   sudo apt update && sudo apt upgrade

   # به‌روزرسانی Docker images
   ./deploy.sh update
   ```

3. **Monitoring:**
   - نصب fail2ban برای محافظت از SSH
   - تنظیم alerting برای down time
   - مانیتورینگ منابع سیستم

## Performance Tuning

### برای سرورهای پر ترافیک:

1. **افزایش تعداد nginx workers:**
   ```nginx
   worker_processes auto;
   worker_connections 2048;
   ```

2. **تنظیم PostgreSQL:**
   ```yaml
   # در docker-compose.production.yml
   db:
     environment:
       POSTGRES_SHARED_PRELOAD_LIBRARIES: 'pg_stat_statements'
     command: |
       postgres 
       -c shared_buffers=256MB 
       -c max_connections=200
   ```

3. **افزایش Redis memory:**
   ```yaml
   redis:
     command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
   ```

## خلاصه

پس از تکمیل این مراحل، Docmost شما در آدرس سرور در دسترس خواهد بود:

- 🌍 **وب‌سایت:** http://your-server-ip
- 📋 **API:** http://your-server-ip/api
- 📊 **Health Check:** http://your-server-ip/health

برای سوالات و مشکلات، لاگ‌ها را بررسی کرده و از دستورات عیب‌یابی استفاده کنید. 