# 📑 URSUS File Index & Guide

Complete guide to all files in the URSUS project.

---

## 📖 Documentation Files (Read These First!)

### 1. **START_HERE.md** ⭐ START HERE
- **What it is:** Quick intro & orientation guide
- **Read if:** You're new to URSUS
- **Time:** 5 minutes
- **Key topics:**
  - What URSUS does
  - The 3 Stripe keys you need
  - Quick start 3-step process
  - Common issues & fixes

### 2. **SETUP_GUIDE.md**
- **What it is:** Step-by-step Stripe configuration
- **Read if:** You need to get your Stripe keys
- **Time:** 15 minutes
- **Key topics:**
  - How to get STRIPE_SECRET_KEY
  - How to get CONNECTED_ACCOUNT_ID
  - How to get STRIPE_WEBHOOK_SECRET
  - Configuration methods
  - Troubleshooting

### 3. **README.md**
- **What it is:** Complete project overview
- **Read if:** You want the full picture
- **Time:** 20 minutes
- **Key topics:**
  - Project description
  - Features overview
  - API endpoints
  - Usage examples
  - Security features
  - Support info

### 4. **QUICK_REFERENCE.txt**
- **What it is:** Fast lookup card
- **Read if:** You need a command or fact quickly
- **Time:** 2 minutes (look up specific item)
- **Key topics:**
  - The 3 Stripe keys at a glance
  - Common commands
  - Money flow diagram
  - Support contact
  - Troubleshooting commands

### 5. **ARCHITECTURE.md**
- **What it is:** Technical deep dive
- **Read if:** You want to understand the system
- **Time:** 30 minutes
- **Key topics:**
  - System overview diagrams
  - Three Stripe accounts explained
  - API endpoints
  - Security layers
  - Fee calculation
  - Deployment architecture
  - Data storage
  - Webhook flow

### 6. **DEPLOYMENT_CHECKLIST.md**
- **What it is:** Step-by-step verification guide
- **Read if:** You want to confirm everything works
- **Time:** 15 minutes (to complete)
- **Key topics:**
  - Pre-deployment checklist
  - Stripe configuration verification
  - Deployment steps
  - Verification tests
  - Security checks
  - Monitoring setup
  - Final verification

### 7. **CONFIG_README.md**
- **What it is:** Configuration app documentation
- **Read if:** You want to understand the web interface
- **Time:** 10 minutes
- **Key topics:**
  - How to use config app
  - Web interface features
  - Security of configuration
  - Troubleshooting config issues

---

## 🐍 Application Files

### **app.py** (582 lines)
- **Purpose:** Main URSUS gateway service
- **What it does:**
  - Receives payment requests via API
  - Creates PaymentIntents on Stripe
  - Receives and processes webhooks
  - Calculates fees automatically
  - Transfers funds to connected account
  - Handles refunds
  - Provides health check endpoint
- **Key features:**
  - API authentication
  - Rate limiting
  - Error handling
  - Logging
  - Idempotency protection
- **Runs on:** Port 4242 (behind Nginx)
- **Requires:** STRIPE_SECRET_KEY, CONNECTED_ACCOUNT_ID, STRIPE_WEBHOOK_SECRET

### **config_app.py** (150 lines)
- **Purpose:** Web interface for configuration
- **What it does:**
  - Displays configuration form
  - Validates Stripe keys format
  - Saves configuration to .env file
  - Provides success/error feedback
- **Key features:**
  - Beautiful modern UI
  - Real-time validation
  - Password fields for secrets
  - Mobile-responsive
- **Runs on:** Port 5000
- **Requires:** Flask, python-dotenv

---

## 🎨 Frontend Files

### **templates/index.html** (250 lines)
- **Purpose:** Configuration app user interface
- **What it does:**
  - Form for entering 3 Stripe keys
  - Real-time form validation
  - Success/error alerts
  - Responsive design
- **Features:**
  - Beautiful gradient design
  - Mobile-friendly
  - Clear labels & instructions
  - Secure password fields
  - Loading state
  - Form reset button

---

## 🚀 Deployment & Configuration Files

### **deploy.sh** (427 lines)
- **Purpose:** Automatic production deployment
- **What it does:**
  1. Updates system packages
  2. Creates 'ursus' user
  3. Configures firewall
  4. Deploys application
  5. Sets up Python environment
  6. Creates .env from example
  7. Creates systemd service
  8. Configures Nginx
  9. Obtains SSL certificate
  10. Sets up log rotation
  11. Configures Fail2Ban
  12. Sets up monitoring
- **Usage:** `sudo bash deploy.sh`
- **Installs:** 
  - Python3, Nginx, Certbot
  - Gunicorn, Fail2Ban
  - Ufw firewall

### **fix_deployment.sh** (211 lines)
- **Purpose:** Troubleshooting & fixing deployment issues
- **What it does:**
  1. Checks virtual environment
  2. Checks gunicorn installation
  3. Fixes file permissions
  4. Validates app.py
  5. Tests gunicorn manually
  6. Recreates systemd service
  7. Checks .env configuration
  8. Reloads and restarts service
- **Usage:** `sudo bash fix_deployment.sh`
- **When to use:** If URSUS isn't starting or working

### **run_config.sh** (30 lines)
- **Purpose:** Easy launcher for config app
- **What it does:**
  - Activates virtual environment (if on VPS)
  - Runs config_app.py
- **Usage:** `bash run_config.sh`

---

## 📦 Configuration & Dependencies

### **requirements.txt** (45 lines)
- **Purpose:** Python dependencies list
- **Includes:**
  - Flask (web framework)
  - Stripe (payment SDK)
  - Flask-Limiter (rate limiting)
  - python-dotenv (env var loading)
  - Gunicorn (production server)
- **Usage:** `pip install -r requirements.txt`

### **env.example** (64 lines)
- **Purpose:** Example environment variables
- **What to do:**
  1. Copy to `.env`
  2. Fill in with your actual values
  3. Keep secure (never commit .env!)
- **Variables:**
  - STRIPE_SECRET_KEY (required)
  - STRIPE_WEBHOOK_SECRET (required)
  - CONNECTED_ACCOUNT_ID (required)
  - URSUS_API_KEY (auto-generated)
  - FLASK_ENV (production/development)
  - PORT (default: 4242)
  - PLATFORM_NAME (optional)
  - CONNECTED_NAME (optional)

---

## 📂 Directory Structure

```
ursus/
├── 📖 Documentation
│   ├── START_HERE.md              ← Begin here!
│   ├── README.md                  ← Project overview
│   ├── SETUP_GUIDE.md             ← Configuration steps
│   ├── QUICK_REFERENCE.txt        ← Quick lookup
│   ├── ARCHITECTURE.md            ← Technical details
│   ├── DEPLOYMENT_CHECKLIST.md    ← Verification
│   ├── CONFIG_README.md           ← Config app docs
│   └── FILE_INDEX.md              ← This file!
│
├── 🐍 Python Code
│   ├── app.py                     ← Main gateway
│   ├── config_app.py              ← Configuration web app
│   └── requirements.txt           ← Dependencies
│
├── 🎨 Frontend
│   └── templates/
│       └── index.html             ← Config UI
│
├── 🚀 Deployment
│   ├── deploy.sh                  ← Automatic deployment
│   ├── fix_deployment.sh          ← Troubleshooting
│   ├── run_config.sh              ← Config launcher
│   └── env.example                ← Example config
│
└── 📁 On VPS Only (After deployment)
    └── /home/ursus/ursus/
        ├── .env                   ← Your actual config
        ├── venv/                  ← Virtual environment
        └── /var/log/ursus/        ← Log files
```

---

## 🔍 Quick File Lookup

### "I need to configure URSUS"
→ Read: **SETUP_GUIDE.md** or **START_HERE.md**
→ Run: `python3 config_app.py`

### "I want to understand how it works"
→ Read: **ARCHITECTURE.md**

### "I need a command quickly"
→ Check: **QUICK_REFERENCE.txt**

### "Something isn't working"
→ Check: **DEPLOYMENT_CHECKLIST.md**
→ Run: `sudo bash fix_deployment.sh`

### "I want the full technical details"
→ Read: **README.md** + **ARCHITECTURE.md**

### "I want to deploy to a new server"
→ Run: `sudo bash deploy.sh`

### "I'm debugging the config app"
→ Read: **CONFIG_README.md**

---

## 📊 File Sizes

| File | Size | Type |
|------|------|------|
| ARCHITECTURE.md | 24 KB | Documentation |
| README.md | 11 KB | Documentation |
| SETUP_GUIDE.md | 6.7 KB | Documentation |
| DEPLOYMENT_CHECKLIST.md | 7.4 KB | Documentation |
| QUICK_REFERENCE.txt | 6.5 KB | Documentation |
| CONFIG_README.md | 3.3 KB | Documentation |
| START_HERE.md | ~5 KB | Documentation |
| app.py | 20 KB | Code |
| deploy.sh | 13 KB | Script |
| fix_deployment.sh | 7.0 KB | Script |
| config_app.py | 4.6 KB | Code |
| requirements.txt | 1.2 KB | Config |
| templates/index.html | ~8 KB | UI |
| run_config.sh | 691 B | Script |
| **Total** | **~120 KB** | **Complete system** |

---

## 🎯 Reading Roadmap

**First Time?** Follow this order:
1. START_HERE.md (5 min)
2. SETUP_GUIDE.md (15 min)
3. Run config_app.py (5 min)
4. Check status (2 min)
5. **Total: 27 minutes** ✓

**Want Full Understanding?**
1. START_HERE.md (5 min)
2. README.md (20 min)
3. SETUP_GUIDE.md (15 min)
4. ARCHITECTURE.md (30 min)
5. **Total: 70 minutes** ✓

**Troubleshooting?**
1. QUICK_REFERENCE.txt (2 min)
2. DEPLOYMENT_CHECKLIST.md (15 min)
3. Run fix_deployment.sh (5 min)
4. **Total: 22 minutes** ✓

---

## 💾 What Gets Created/Modified

### During Development
- `.env` (if you manually create it)
- `venv/` (virtual environment)

### During Deployment (sudo bash deploy.sh)
- `/home/ursus/ursus/` (app directory)
- `/home/ursus/.env` (configuration)
- `/home/ursus/venv/` (python environment)
- `/etc/nginx/sites-available/ursus` (nginx config)
- `/etc/systemd/system/ursus.service` (systemd service)
- `/var/log/ursus/` (log directory)
- `/etc/logrotate.d/ursus` (log rotation config)
- `/etc/fail2ban/` (security config)

### Using Configuration App
- `/home/ursus/ursus/.env` (updated with your keys)

---

## 🔐 Important Notes

- **Never commit** `.env` file to git
- **Never share** your STRIPE_SECRET_KEY
- **Never commit** your CONNECTED_ACCOUNT_ID
- **Keep .env permissions** as 600 (read-only by owner)
- **Use sk_live_** in production, not sk_test_
- **Keep documentation** for reference
- **Backup your .env** file in a secure location

---

## 📞 Getting Help

**Have a question about a file?**
- README.md - Project overview
- CONFIG_README.md - Configuration app
- SETUP_GUIDE.md - Getting Stripe keys
- ARCHITECTURE.md - How it works
- DEPLOYMENT_CHECKLIST.md - Verification
- QUICK_REFERENCE.txt - Commands

**Still stuck?**
- Email: contact@deskcodes.com
- Phone: +1 206-408-6213
- Hours: Mon-Fri 9AM-6PM EST

---

**Last Updated:** December 2025  
**URSUS Version:** 2.0  
**Status:** Production Ready ✓

