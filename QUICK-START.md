# راه‌اندازی سریع Docmost Production

## مراحل خلاصه برای راه‌اندازی با SSL

### 1️⃣ آماده‌سازی SSL Certificate
```bash
# فایل‌های SSL را در پوشه ssl قرار دهید:
ssl/certificate.crt  # گواهی SSL شما
ssl/private.key      # کلید خصوصی شما
ssl/CSR.txt         # ✅ موجود است
```

### 2️⃣ تنظیم Environment Variables
```bash
# فایل production.env را کپی و ویرایش کنید:
cp production.env my-production.env
```

**حتماً این مقادیر را تغییر دهید:**
```env
APP_SECRET=your-super-long-random-secret-key-here
SESSION_SECRET=another-long-random-secret-here  
JWT_SECRET=jwt-secret-very-long-and-secure
DB_PASSWORD=your-database-strong-password
```

### 3️⃣ راه‌اندازی

#### Windows PowerShell:
```powershell
# نام فایل environment را تغییر دهید
Rename-Item my-production.env production.env

# اجرای deployment
.\scripts\deploy.ps1
```

#### Linux/macOS:
```bash
# نام فایل environment را تغییر دهید
mv my-production.env production.env

# اجرای deployment
./scripts/deploy.sh
```

### 4️⃣ بررسی نتیجه
✅ سایت شما در آدرس زیر باید در دسترس باشد:
- **https://smartx.ir**

## کامندهای مفید

### مشاهده وضعیت:
```bash
docker-compose -f docker-compose.production.yml ps
```

### مشاهده لاگ‌ها:
```bash
docker-compose -f docker-compose.production.yml logs -f
```

### متوقف کردن:
```bash
docker-compose -f docker-compose.production.yml down
```

### Backup (Windows):
```powershell
.\scripts\backup.ps1
```

### Backup (Linux/macOS):
```bash
./scripts/backup.sh
```

---

## ⚠️ نکات مهم

1. **SSL Certificate**: حتماً گواهی معتبر استفاده کنید
2. **رمزهای عبور**: هرگز رمزهای پیش‌فرض استفاده نکنید
3. **Backup**: قبل از هر به‌روزرسانی backup بگیرید
4. **Firewall**: پورت‌های 80 و 443 باز باشند

📖 **راهنمای کامل**: `PRODUCTION-SETUP.md` 