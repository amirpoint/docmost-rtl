# راه‌اندازی Docmost در محیط Production با SSL

این راهنما برای راه‌اندازی Docmost در محیط production با nginx و SSL certificate طراحی شده است.

## پیش‌نیازها

### 1. سیستم
- Docker و Docker Compose نصب شده باشند
- دامین به سرور شما متصل باشد (`smartx.ir`)
- گواهی SSL معتبر داشته باشید

### 2. گواهی SSL
از آنجایی که CSR.txt موجود است، باید گواهی SSL را از CA دریافت کرده باشید:

```bash
# فایل‌های SSL باید در پوشه ssl قرار گیرند:
ssl/
├── certificate.crt    # گواهی SSL شما
├── private.key        # کلید خصوصی
└── CSR.txt           # موجود است
```

## مراحل راه‌اندازی

### مرحله 1: آماده‌سازی فایل‌های SSL
```bash
# گواهی SSL و کلید خصوصی را در پوشه ssl قرار دهید
cp your-certificate.crt ssl/certificate.crt
cp your-private-key.key ssl/private.key

# اطمینان حاصل کنید که فایل‌ها وجود دارند
ls -la ssl/
```

### مرحله 2: تنظیم متغیرهای محیطی
```bash
# فایل production.env را کپی کنید و ویرایش کنید
cp production.env production.env.local

# متغیرهای مهم زیر را تغییر دهید:
nano production.env.local
```

**متغیرهای مهم که باید تغییر دهید:**
- `APP_SECRET`: یک کلید طولانی و تصادفی
- `SESSION_SECRET`: کلید session مجزا
- `JWT_SECRET`: کلید JWT
- `DB_PASSWORD`: رمز عبور قوی برای پایگاه داده

**نکته امنیتی:** هرگز رمزهای پیش‌فرض را در production استفاده نکنید!

### مرحله 3: راه‌اندازی

#### برای Linux/macOS:
```bash
# اجرای اسکریپت deployment
./scripts/deploy.sh
```

#### برای Windows PowerShell:
```powershell
# اجرای اسکریپت deployment
.\scripts\deploy.ps1
```

این اسکریپت:
- بررسی پیش‌نیازها
- ایجاد پوشه‌های مورد نیاز
- بررسی وجود فایل‌های SSL
- راه‌اندازی تمام سرویس‌ها
- اجرای migration پایگاه داده
- بررسی سلامت سرویس‌ها

### مرحله 4: بررسی نتیجه
پس از اجرای موفق، می‌توانید وب‌سایت را مشاهده کنید:
- **HTTP**: `http://smartx.ir` (به HTTPS redirect می‌شود)
- **HTTPS**: `https://smartx.ir`

## مدیریت سرویس

### کامندهای مفید
```bash
# مشاهده لاگ‌ها
docker-compose -f docker-compose.production.yml logs -f

# مشاهده لاگ یک سرویس خاص
docker-compose -f docker-compose.production.yml logs -f nginx
docker-compose -f docker-compose.production.yml logs -f docmost

# راه‌اندازی مجدد سرویس‌ها
docker-compose -f docker-compose.production.yml restart

# متوقف کردن سرویس‌ها
docker-compose -f docker-compose.production.yml down

# راه‌اندازی مجدد کامل (Linux/macOS)
docker-compose -f docker-compose.production.yml down
./scripts/deploy.sh

# راه‌اندازی مجدد کامل (Windows)
docker-compose -f docker-compose.production.yml down
.\scripts\deploy.ps1
```

### پشتیبان‌گیری

#### Linux/macOS:
```bash
# ایجاد backup از پایگاه داده
./scripts/backup.sh

# پشتیبان‌ها در پوشه ./backups ذخیره می‌شوند
ls -la backups/
```

#### Windows PowerShell:
```powershell
# ایجاد backup از پایگاه داده
.\scripts\backup.ps1

# پشتیبان‌ها در پوشه .\backups ذخیره می‌شوند
Get-ChildItem backups\
```

### به‌روزرسانی

#### Linux/macOS:
```bash
# به‌روزرسانی به آخرین نسخه
./scripts/update.sh
```

#### Windows PowerShell:
```powershell
# به‌روزرسانی به آخرین نسخه
.\scripts\update.ps1
```

## ساختار سرویس‌ها

### سرویس‌های اجرا شده:
1. **nginx** (Port 80, 443): Reverse proxy با SSL
2. **docmost**: اپلیکیشن اصلی (Port 3000 internal)
3. **postgres**: پایگاه داده (Port 5432 internal)
4. **redis**: Cache و Session storage (Port 6379 internal)

### Volume‌ها:
- `docmost_data`: فایل‌های اپلیکیشن
- `postgres_data`: داده‌های پایگاه داده
- `redis_data`: داده‌های Redis

## امنیت

### تنظیمات امنیتی اعمال شده:
- ✅ HTTPS اجباری (HTTP به HTTPS redirect می‌شود)
- ✅ Modern SSL/TLS protocols (TLSv1.2, TLSv1.3)
- ✅ Security headers (HSTS, X-Frame-Options, etc.)
- ✅ Rate limiting
- ✅ Strong cipher suites

### توصیه‌های امنیتی:
1. رمزهای قوی استفاده کنید
2. به‌روزرسانی‌های امنیتی را منظم انجام دهید
3. لاگ‌ها را بررسی کنید
4. پشتیبان‌گیری منظم انجام دهید

## عیب‌یابی

### مشکلات رایج:
1. **SSL Certificate Error**: 
   - بررسی کنید فایل‌های SSL در مسیر صحیح قرار دارند
   - اطمینان حاصل کنید certificate معتبر است

2. **Database Connection Error**:
   - بررسی کنید PostgreSQL running باشد
   - رمز عبور DB_PASSWORD صحیح باشد

3. **Application Not Loading**:
   - لاگ‌های docmost service را بررسی کنید
   - مطمئن شوید migration اجرا شده است

### مشاهده لاگ‌ها:
```bash
# تمام لاگ‌ها
docker-compose -f docker-compose.production.yml logs

# لاگ nginx
docker-compose -f docker-compose.production.yml logs nginx

# لاگ اپلیکیشن
docker-compose -f docker-compose.production.yml logs docmost
```

### Healthcheck:
```bash
# بررسی سلامت سرویس‌ها
docker-compose -f docker-compose.production.yml ps
```

## پشتیبانی
در صورت بروز مشکل، ابتدا لاگ‌ها را بررسی کنید و سپس با تیم پشتیبانی تماس بگیرید. 