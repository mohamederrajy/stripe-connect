# 🚀 START HERE - URSUS Configuration & Deployment

Welcome to **URSUS v2.0** - Your Stripe Connect Payment Gateway!

This document will guide you through everything step-by-step.

---

## 📖 What You Need to Know

**URSUS** is a service that:

1. **Receives payments** from customers on your Stripe Platform Account
2. **Automatically splits** the money between your platform and your vendor
3. **Runs 24/7** with auto-restart and monitoring
4. **Handles everything** - no manual transfers needed!

---

## 🎯 The 3 Things You MUST Have from Stripe

Before doing anything, get these 3 items from your Stripe account:

```
┌──────────────────────────────────┐
│  1️⃣  STRIPE_SECRET_KEY           │
│      Format: sk_live_xxxxx...    │
│      From: Developers → API Keys │
├──────────────────────────────────┤
│  2️⃣  CONNECTED_ACCOUNT_ID        │
│      Format: acct_xxxxx...       │
│      From: Connected Accounts    │
├──────────────────────────────────┤
│  3️⃣  STRIPE_WEBHOOK_SECRET       │
│      Format: whsec_xxxxx...      │
│      From: Developers → Webhooks │
└──────────────────────────────────┘
```

**👉 Don't have these yet?** Read **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** to get them!

---

## ⏱️ Quick Start (3 Minutes)

### Step 1: Get Your 3 Stripe Keys
- [See detailed instructions](./SETUP_GUIDE.md#-how-to-get-each-key)
- Takes about 5-10 minutes

### Step 2: Run the Configuration App
```bash
# On your local machine or VPS
python3 config_app.py
```

### Step 3: Enter Your Keys
- Open browser: **http://localhost:5000**
- Paste the 3 keys
- Click **Save Configuration**

### Step 4: Restart URSUS
```bash
systemctl restart ursus
```

### Step 5: Test It
```bash
curl https://your-domain.com/health
# Should return: {"status": "healthy", ...}
```

**Done! 🎉**

---

## 📚 Documentation Files

Here's what each document is for:

| File | Purpose | Read When |
|------|---------|-----------|
| **[README.md](./README.md)** | Project overview | You want the big picture |
| **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** | Get Stripe keys & configure | First time setup |
| **[QUICK_REFERENCE.txt](./QUICK_REFERENCE.txt)** | Commands & quick facts | You need a command |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | How URSUS works inside | You want technical details |
| **[DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)** | Verify your setup | You want to confirm everything works |
| **[CONFIG_README.md](./CONFIG_README.md)** | Config app details | You want to know about config_app.py |

---

## 🛠️ Configuration Methods

### **Method A: Web Interface** ✅ RECOMMENDED

```bash
python3 config_app.py
```

Then open **http://localhost:5000** in your browser.

**Pros:**
- ✅ Beautiful, modern UI
- ✅ Real-time validation
- ✅ Can't make typos
- ✅ Works on desktop & mobile

**Cons:**
- None really! 😄

---

### **Method B: Edit .env File**

```bash
nano /home/ursus/ursus/.env
```

Find these lines and update them:

```env
STRIPE_SECRET_KEY=sk_live_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_secret_here
CONNECTED_ACCOUNT_ID=acct_your_account_here
```

Save: `Ctrl+X` → `Y` → `Enter`

**Pros:**
- Simple text editing
- Fast if you know what you're doing

**Cons:**
- Easy to make typos
- No validation
- Less visual feedback

---

### **Method C: Environment Variables**

```bash
export STRIPE_SECRET_KEY="sk_live_..."
export STRIPE_WEBHOOK_SECRET="whsec_..."
export CONNECTED_ACCOUNT_ID="acct_..."
python3 app.py
```

**Pros:**
- Good for containers & CI/CD

**Cons:**
- Not persistent after reboot
- Not recommended for production

---

## 🚀 Deployment Scenarios

### Scenario 1: Local Testing
```bash
cd ~/Documents/ursus
python3 config_app.py          # Configure (port 5000)
python3 app.py                 # Run URSUS (port 4242)
```

### Scenario 2: Fresh VPS Deployment
```bash
ssh root@your-server.com
cd /path/to/ursus
sudo bash deploy.sh            # Full automatic setup
```

### Scenario 3: Already Deployed
```bash
ssh root@your-server.com
cd /home/ursus/ursus
source venv/bin/activate
python3 config_app.py          # Just configure
```

### Scenario 4: Troubleshooting
```bash
ssh root@your-server.com
cd /home/ursus/ursus
sudo bash fix_deployment.sh    # Diagnose & fix
```

---

## ✅ After Configuration

Once you've saved your Stripe keys:

```bash
# 1. Restart the service
systemctl restart ursus

# 2. Check it's running
systemctl status ursus

# 3. Test the health endpoint
curl https://your-domain.com/health

# 4. View the logs
journalctl -u ursus -f

# 5. Check configuration was saved
cat /home/ursus/ursus/.env
```

**You should see:**
- ✅ Service is "active (running)"
- ✅ Health endpoint returns `{"status": "healthy", ...}`
- ✅ No errors in logs
- ✅ Your keys are in .env file

---

## 🎯 How Money Flows

```
Customer sends $100
      ↓
URSUS receives on Platform Account
      ↓
Stripe webhook fires
      ↓
URSUS calculates:
  • Stripe fee: $3.20
  • Platform gets: $0.97
  • Vendor gets: $95.83
      ↓
URSUS automatically transfers $95.83
      ↓
Vendor receives payment in their account ✓
Platform keeps commission ✓
```

---

## 🔐 Security

URSUS protects you with:

✅ API Key authentication  
✅ Webhook signature verification  
✅ Rate limiting (prevents abuse)  
✅ Input validation (prevents bad data)  
✅ SSL/TLS encryption (HTTPS)  
✅ Fail2Ban (blocks bad actors)  
✅ Automatic logging (audit trail)  

---

## 🆘 Common Issues & Fixes

**"Service won't start"?**
```bash
sudo journalctl -u ursus -n 50
sudo bash fix_deployment.sh
```

**"Can't access config app"?**
```bash
# Make sure it's running
ps aux | grep config_app

# Check port
netstat -tlnp | grep 5000
```

**"Can't find Stripe keys"?**
→ Read [SETUP_GUIDE.md](./SETUP_GUIDE.md) carefully

**"Health check failing"?**
```bash
curl -v https://your-domain.com/health
sudo journalctl -u ursus -f
```

---

## 📞 Need Help?

### Documentation
- 📖 Read [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed steps
- 📖 Check [ARCHITECTURE.md](./ARCHITECTURE.md) to understand how it works
- 📖 See [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) to verify everything

### Support
- 📧 Email: contact@deskcodes.com
- 📞 Phone: +1 206-408-6213
- 🕐 Hours: Mon-Fri 9AM-6PM EST
- 📍 Address: 182-21 150th Avenue, Springfield Gardens NY 11413

---

## 📋 My First 30 Minutes Checklist

- [ ] Read this file (START_HERE.md) - 2 min
- [ ] Read [SETUP_GUIDE.md](./SETUP_GUIDE.md) - 5 min
- [ ] Get 3 Stripe keys from dashboard - 10 min
- [ ] Run config_app.py and enter keys - 3 min
- [ ] Restart service: `systemctl restart ursus` - 1 min
- [ ] Test health endpoint - 1 min
- [ ] ✅ Done! You're live!

**Total: ~22 minutes** ⏱️

---

## 🎉 You're Ready!

URSUS is production-ready and waiting for you to configure it.

### Next Step
👉 **[Go to SETUP_GUIDE.md](./SETUP_GUIDE.md)** to start!

---

## 📊 File Structure

```
ursus/
├── 📄 START_HERE.md           ← You are here! 🎯
├── 📄 README.md               ← Full project overview
├── 📄 SETUP_GUIDE.md          ← Step-by-step setup
├── 📄 QUICK_REFERENCE.txt     ← Commands & tips
├── 📄 ARCHITECTURE.md         ← Technical details
├── 📄 DEPLOYMENT_CHECKLIST.md ← Verification steps
├── 📄 CONFIG_README.md        ← Config app docs
│
├── 🐍 app.py                  ← Main URSUS gateway
├── 🐍 config_app.py           ← Configuration web app
├── 📁 templates/
│   └── index.html             ← Config UI
│
├── 📜 deploy.sh               ← Automatic deployment
├── 📜 fix_deployment.sh       ← Troubleshooting
├── 📜 run_config.sh           ← Config launcher
├── 📜 requirements.txt        ← Python dependencies
└── 📜 env.example             ← Example config
```

---

**Happy Stripe Connect integration! 🚀**

*URSUS v2.0 | Production Ready | Made with ❤️*

