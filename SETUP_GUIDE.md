# 🚀 URSUS Setup & Configuration Guide

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│          URSUS Stripe Connect Gateway v2.0                  │
│                                                             │
│  Your Platform Account ←→ Connected Account (Vendor)       │
│  (Collects payments)    (Receives vendor share)            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 What You Need to Configure

You need **3 things from Stripe** to make URSUS work:

| # | Name | Format | What It Is | Where to Get It |
|---|------|--------|-----------|-----------------|
| 1 | **Stripe Secret Key** | `sk_live_xxx` | Your Platform account's API key | [Stripe Dashboard](https://dashboard.stripe.com) → Developers → API Keys |
| 2 | **Connected Account ID** | `acct_xxx` | Vendor's Stripe account ID | [Stripe Dashboard](https://dashboard.stripe.com) → Connected Accounts |
| 3 | **Webhook Secret** | `whsec_xxx` | Signature verification key for webhooks | [Stripe Dashboard](https://dashboard.stripe.com) → Developers → Webhooks |

---

## 🛠️ How to Get Each Key

### **1️⃣ Stripe Secret Key (sk_live_...)**

**Step-by-step:**
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Make sure you're in your **Platform Account** (check top-left dropdown)
3. Click **Developers** in the left menu
4. Click **API Keys** tab
5. Copy the **Secret Key** (⚠️ NOT the Publishable Key!)
6. It should start with `sk_live_` or `sk_test_`

**Format:** `sk_live_[your-secret-key-here]`

---

### **2️⃣ Connected Account ID (acct_...)**

**Step-by-step:**
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Click **Connected Accounts** in the left menu
3. Find your vendor's account in the list
4. Click on it
5. Copy the **Account ID** from the top (starts with `acct_`)

**Example:** `acct_1K4mZ5Ax7x7x7x7x7`

**Note:** This is the Stripe account of your vendor/merchant who will receive the payments.

---

### **3️⃣ Webhook Secret (whsec_...)**

**Step-by-step:**
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Click **Developers** in the left menu
3. Click **Webhooks** tab
4. Click **Add an endpoint** button
5. Fill in:
   - **Endpoint URL:** `https://your-domain.com/webhook`
   - Replace `your-domain.com` with your actual domain
6. Check these events:
   - ✅ `charge.succeeded`
   - ✅ `charge.captured`
   - ✅ `charge.refunded`
7. Click **Add endpoint**
8. Click on the webhook you just created
9. Scroll down and copy **Signing secret** (starts with `whsec_`)

**Example:** `whsec_test_abcdef1234567890`

---

## 💻 How to Configure URSUS

### **Option A: Using the Configuration App (Recommended for beginners)**

This is the easiest way! We've created a simple web interface.

**On your local machine:**
```bash
cd ~/Documents/ursus
python3 config_app.py
```

Then open: **http://localhost:5000**

**On your VPS server:**
```bash
# SSH into your server
ssh root@your-server.com

# Go to URSUS directory
cd /home/ursus/ursus

# Activate environment
source venv/bin/activate

# Run the config app
python3 config_app.py
```

Then open: **http://your-server-ip:5000**

**What happens:**
1. Open the web interface in your browser
2. Paste the 3 keys you got from Stripe
3. Click **Save Configuration**
4. Done! ✅

---

### **Option B: Editing .env file manually**

**On your VPS:**
```bash
# SSH into your server
ssh root@your-server.com

# Edit the .env file
nano /home/ursus/ursus/.env
```

**Change these lines:**
```env
STRIPE_SECRET_KEY=sk_live_your_actual_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_actual_secret_here
CONNECTED_ACCOUNT_ID=acct_your_account_id_here
```

**Save:** Press `Ctrl + X`, then `Y`, then `Enter`

---

## ✅ After Configuration

Once you've entered the 3 keys:

```bash
# Restart URSUS service
systemctl restart ursus

# Check if it's running
systemctl status ursus

# View live logs
journalctl -u ursus -f

# Test with
curl https://your-domain.com/health
```

You should see: `{"status": "healthy", ...}`

---

## 🎯 How URSUS Works (After Configuration)

```
Customer sends payment
       ↓
URSUS receives payment to Platform Account
       ↓
Stripe webhook fires (charge.succeeded)
       ↓
URSUS calculates fees:
  - Stripe fee: 2.9% + $0.30
  - Platform commission: 1% of net
  - Vendor share: remainder
       ↓
URSUS automatically transfers vendor share
       ↓
Vendor receives payment in Connected Account ✓
Platform keeps commission ✓
```

---

## 🔐 Security Notes

✅ **Secret keys are hidden** in the web interface (password fields)  
✅ **Validation** ensures keys have correct format  
✅ **Webhook signature verification** prevents fake events  
✅ **Rate limiting** prevents abuse  
✅ **Idempotency** prevents duplicate transfers  

---

## 📞 Configuration App Details

**Files included:**
- `config_app.py` - Flask backend
- `templates/index.html` - Web interface
- `run_config.sh` - Easy launcher
- `CONFIG_README.md` - Detailed docs

**Features:**
- 🎨 Modern, responsive UI
- ✓ Real-time validation
- 🔐 Format checking
- 📱 Mobile friendly
- ⚡ Instant feedback

---

## 🆘 Troubleshooting

**"Can't connect to localhost:5000"?**
- Make sure Flask is running: `python3 config_app.py`
- Check your firewall isn't blocking port 5000

**"Can't find Stripe keys"?**
- Go to [Stripe Dashboard](https://dashboard.stripe.com)
- Make sure you're logged in to the right account
- Toggle account dropdown at top-left if you have multiple

**"Webhook is failing"?**
- Make sure domain is correct: `https://your-domain.com/webhook`
- Make sure you selected the right events
- Check that your domain is live and accessible

**"Service won't start"?**
- Run: `journalctl -u ursus -f` to see error logs
- Make sure all 3 keys are valid
- Run: `systemctl restart ursus`

---

## 📋 Checklist

- [ ] Have Stripe account set up
- [ ] Have Platform Account
- [ ] Have Connected Account (vendor)
- [ ] Got `sk_live_...` key
- [ ] Got `acct_...` ID
- [ ] Set up webhook, got `whsec_...`
- [ ] Ran configuration app (or edited .env)
- [ ] Restarted service: `systemctl restart ursus`
- [ ] Tested with: `curl https://your-domain.com/health`
- [ ] Ready to accept payments! 🎉

---

## 🎉 You're Done!

URSUS is now ready to:
- ✅ Accept payments from customers
- ✅ Automatically split funds with your vendor
- ✅ Handle refunds
- ✅ Log all transactions
- ✅ Run 24/7

**Questions? Contact:**
- 📞 +1 206-408-6213
- 📧 contact@deskcodes.com
- ⏰ Mon-Fri: 9AM-6PM EST

