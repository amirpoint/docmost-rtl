# راهنمای راه‌اندازی Docmost با nginx

## پیش‌نیازها

### 1. نصب nginx در Windows
```bash
# دانلود nginx از سایت رسمی
https://nginx.org/en/download.html

# یا استفاده از Chocolatey
choco install nginx

# یا استفاده از Scoop
scoop install nginx
```

### 2. بررسی وجود فایل‌های بیلد شده
مطمئن شوید این پوشه‌ها موجودند:
- `apps/client/dist/`
- `apps/server/dist/`
- `packages/editor-ext/dist/`

## راه‌اندازی

### مرحله 1: تنظیم متغیرهای محیطی

1. فایل `env.production.example` را کپی کرده و نام آن را `.env` بگذارید
2. مقادیر زیر را ویرایش کنید:

```env
APP_URL='http://localhost'  # یا دامنه‌تان
APP_SECRET='REPLACE_WITH_VERY_LONG_SECRET_KEY'
DATABASE_URL='postgresql://docmost:STRONG_DB_PASSWORD@localhost:5432/docmost?schema=public'
REDIS_URL='redis://localhost:6379'
```

### مرحله 2: تنظیم nginx

#### 2.1 ویرایش فایل کانفیگوریشن nginx

فایل `nginx/nginx.conf` را ویرایش کنید و `ROOT_PATH` را با مسیر کامل پروژه‌تان جایگزین کنید:

```nginx
# مثال: اگر پروژه در D:\smart-development\docmost است
root D:/smart-development/docmost/apps/client/dist;
```

#### 2.2 کپی کردن کانفیگوریشن

فایل `nginx/nginx.conf` را به مسیر نصب nginx کپی کنید:

**Windows (nginx نصب شده در C:\nginx):**
```cmd
copy nginx\nginx.conf C:\nginx\conf\nginx.conf
```

**یا در PowerShell:**
```powershell
Copy-Item nginx\nginx.conf C:\nginx\conf\nginx.conf
```

### مرحله 3: راه‌اندازی دیتابیس

```bash
# راه‌اندازی PostgreSQL و Redis
docker-compose up -d db redis

# منتظر ماندن تا دیتابیس آماده شود
timeout /t 10

# اجرای migrations
cd apps\server
pnpm migration:latest
cd ..\..
```

### مرحله 4: راه‌اندازی سرور

```bash
# اجرای سرور در background
cd apps\server
start /B pnpm start:prod > ..\..\logs\server.log 2>&1
cd ..\..
```

### مرحله 5: راه‌اندازی nginx

```bash
# تست کانفیگوریشن nginx
nginx -t

# راه‌اندازی nginx
nginx
# یا اگر nginx قبلاً اجرا است:
nginx -s reload
```

## دستورات مفید

### بررسی وضعیت
```bash
# بررسی nginx
nginx -t

# بررسی پردازش‌های در حال اجرا
tasklist | findstr nginx
tasklist | findstr node

# مشاهده لاگ‌ها
type logs\server.log
```

### توقف سرویس‌ها
```bash
# توقف nginx
nginx -s quit

# توقف سرور Node.js
taskkill /F /IM node.exe

# توقف دیتابیس
docker-compose down
```

### restart سرویس‌ها
```bash
# restart nginx
nginx -s reload

# restart سرور
cd apps\server
taskkill /F /IM node.exe
start /B pnpm start:prod > ..\..\logs\server.log 2>&1
cd ..\..
```

## آدرس‌ها

پس از راه‌اندازی موفق:

- **وب‌سایت اصلی:** http://localhost
- **API:** http://localhost/api
- **Health Check:** http://localhost/health

## عیب‌یابی

### مشکلات رایج

1. **nginx شروع نمی‌شود:**
   - بررسی کنید پورت 80 آزاد باشد
   - از دستور `nginx -t` برای بررسی کانفیگوریشن استفاده کنید

2. **API کار نمی‌کند:**
   - مطمئن شوید سرور Node.js در حال اجرا است
   - لاگ‌های سرور را بررسی کنید: `type logs\server.log`

3. **فایل‌های static لود نمی‌شوند:**
   - مسیر `root` در nginx.conf را بررسی کنید
   - مطمئن شوید مسیر به درستی نوشته شده (با / به جای \)

4. **WebSocket کار نمی‌کند:**
   - فایروال را بررسی کنید
   - تنظیمات proxy در nginx را چک کنید

### لاگ‌ها

- **nginx errors:** در پوشه‌ی نصب nginx: `logs/error.log`
- **nginx access:** در پوشه‌ی نصب nginx: `logs/access.log`
- **سرور Docmost:** `logs/server.log`

## نکات امنیتی (برای production)

1. **SSL/TLS:** برای production حتماً HTTPS استفاده کنید
2. **Firewall:** پورت‌های غیرضروری را ببندید
3. **کلیدهای امنیتی:** `APP_SECRET` قوی استفاده کنید
4. **دیتابیس:** رمز عبور قوی برای دیتابیس تنظیم کنید
5. **Updates:** nginx و سیستم‌عامل را به‌روز نگه دارید 