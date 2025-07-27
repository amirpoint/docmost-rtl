<div align="center">
    <h1><b>Docmost RTL</b></h1>
    <p>
        Fork of Docmost with RTL support and production-ready deployment configuration.
        <br />
        <a href="https://help.smartx.ir"><strong>Live Demo</strong></a> | 
        <a href="https://docmost.com/docs"><strong>Original Documentation</strong></a> |
        <a href="https://github.com/docmost/docmost"><strong>Original Repository</strong></a>
    </p>
</div>
<br />

## 🚀 About This Fork

This is a customized fork of [Docmost](https://github.com/docmost/docmost) with the following enhancements:

### ✨ Added Features
- **RTL (Right-to-Left) Support**: Full support for Persian/Arabic languages
- **Production-Ready Configuration**: Docker Compose setup with nginx and SSL
- **Persian Fonts**: Integrated IRANSans font family
- **SSL/HTTPS Setup**: Complete SSL certificate configuration
- **Database Optimization**: PostgreSQL with production settings
- **Redis Configuration**: Optimized Redis setup for production
- **Backup Scripts**: Automated database backup functionality
- **Deployment Scripts**: PowerShell and Bash deployment scripts
- **Custom Domain Support**

### 🔧 Technical Improvements
- **Docker Production Setup**: Multi-stage Docker build optimized for production
- **Nginx Configuration**: Reverse proxy with SSL termination and security headers
- **Environment Management**: Structured environment variable configuration
- **Health Checks**: Container health monitoring
- **Log Management**: Centralized logging configuration
- **Volume Management**: Persistent data storage setup

## 🛠️ Quick Start

### Prerequisites
- Docker and Docker Compose
- SSL Certificate files (`certificate.crt` and `private.key`)
- Domain pointing to your server

### Deployment

#### 1. Clone the repository
```bash
git clone <your-repo-url>
cd docmost-rtl
```

#### 2. Configure SSL certificates
```bash
# Place your SSL certificates in the ssl/ directory
cp your-certificate.crt ssl/certificate.crt
cp your-private-key.key ssl/private.key
```

#### 3. Configure environment variables
```bash
# Copy and edit the environment file
cp production.env.example production.env
# Edit production.env with your settings
```

#### 4. Deploy
```bash
# For Linux/macOS
./scripts/deploy.sh

# For Windows PowerShell
.\scripts\deploy.ps1
```


## 📁 Project Structure

```
docmost-rtl/
├── nginx/                    # Nginx configuration
│   └── nginx.conf           # Production nginx config
├── ssl/                     # SSL certificates
│   ├── certificate.crt      # Your SSL certificate
│   └── private.key          # Your private key
├── scripts/                 # Deployment scripts
│   ├── deploy.sh           # Linux/macOS deployment
│   ├── deploy.ps1          # Windows deployment
│   ├── backup.sh           # Database backup
│   └── update.sh           # Application update
├── docker-compose.production.yml  # Production Docker setup
├── production.env           # Environment variables
└── redis.conf              # Redis production config
```

## 🔄 Management Commands

### View logs
```bash
docker-compose -f docker-compose.production.yml logs -f
```

### Backup database
```bash
# Linux/macOS
./scripts/backup.sh

# Windows
.\scripts\backup.ps1
```

### Update application
```bash
# Linux/macOS
./scripts/update.sh

# Windows
.\scripts\update.ps1
```

### Restart services
```bash
docker-compose -f docker-compose.production.yml restart
```

## 🛡️ Security Features

- **HTTPS Enforcement**: Automatic HTTP to HTTPS redirect
- **Security Headers**: HSTS, X-Frame-Options, XSS Protection
- **Rate Limiting**: API rate limiting protection
- **Modern SSL/TLS**: TLSv1.2 and TLSv1.3 support
- **Strong Cipher Suites**: Secure cipher configuration

## 📊 Monitoring

- **Health Checks**: All containers have health monitoring
- **Log Management**: Centralized logging in `logs/` directory
- **Backup Automation**: Automated database backups
- **Performance Optimization**: PostgreSQL and Redis tuning

## 🤝 Contributing

This is a fork of the original Docmost project. For contributions to the main project, please refer to the [original repository](https://github.com/docmost/docmost).

## 📄 License

This project is based on Docmost, which is licensed under the AGPL 3.0 license. See the [original license](https://github.com/docmost/docmost/blob/main/LICENSE) for details.

## 🙏 Acknowledgments

- **Original Docmost Team**: For the excellent open-source wiki platform
- **Crowdin**: For localization platform access
- **Algolia**: For full-text search capabilities

---

<div align="center">
    <p>
        <strong>Forked from</strong> <a href="https://github.com/docmost/docmost">Docmost</a> | 
        <strong>Live Demo</strong> <a href="https://help.smartx.ir">help.smartx.ir</a>
    </p>
</div>

