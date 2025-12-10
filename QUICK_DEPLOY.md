# ⚡ Quick Deploy to GitHub + Server (5 Minutes)

## For Your Server: 5.161.116.77

---

## 🚀 QUICK START

### Step 1: Push to GitHub (2 minutes)

```bash
cd ~/Documents/ursus

# First time only - configure git
git config --global user.name "Your Name"
git config --global user.email "your.email@gmail.com"

# Initialize and push
git init
git add .
git commit -m "URSUS v2.0 - Stripe Connect Gateway"
git branch -M main
git remote add origin https://github.com/mohamederrajy/stripe-connect.git
git push -u origin main
```

### Step 2: Deploy to Server (3 minutes)

```bash
# Connect to your server
ssh root@5.161.116.77

# Clone from GitHub
git clone https://github.com/mohamederrajy/stripe-connect.git /home/ursus/ursus

# Change to directory
cd /home/ursus/ursus

# Make deployment script executable
chmod +x deploy.sh

# Run deployment (interactive - answers questions)
sudo bash deploy.sh
```

**When prompted:**
- Domain: `pay.yourdomain.com` (or your domain)
- Email: `your.email@gmail.com`
- Confirm: `y`

### Step 3: Configure Stripe Keys (2 minutes)

**On your server:**
```bash
cd /home/ursus/ursus
source venv/bin/activate
python3 config_app.py
```

**In your browser:**
1. Visit: `http://5.161.116.77:5000`
2. Enter your 3 Stripe keys
3. Click: Save Configuration
4. Done! ✓

### Step 4: Restart & Test (1 minute)

```bash
sudo systemctl restart ursus
curl https://your-domain.com/health
```

**Done! Your URSUS gateway is live!** 🎉

---

## 📋 The 3 Things You Need

Before starting, get these from Stripe Dashboard:

```
1. STRIPE_SECRET_KEY = sk_live_...
   From: Stripe Dashboard → Developers → API Keys

2. CONNECTED_ACCOUNT_ID = acct_...
   From: Stripe Dashboard → Connected Accounts

3. STRIPE_WEBHOOK_SECRET = whsec_...
   From: Stripe Dashboard → Developers → Webhooks
   Endpoint URL: https://your-domain.com/webhook
   Events: charge.succeeded, charge.captured, charge.refunded
```

---

## 🌐 Access Your URSUS Gateway

After deployment, access at:

| Purpose | URL |
|---------|-----|
| **Configuration** | http://5.161.116.77:5000 |
| **Health Check** | https://your-domain.com/health |
| **API Endpoint** | https://your-domain.com/create-payment-intent |
| **Webhook** | https://your-domain.com/webhook |

---

## 🔧 Useful Commands

```bash
# SSH to server
ssh root@5.161.116.77

# Check URSUS status
sudo systemctl status ursus

# View logs
sudo journalctl -u ursus -f

# Restart service
sudo systemctl restart ursus

# Run config app
cd /home/ursus/ursus && source venv/bin/activate && python3 config_app.py

# Update from GitHub
cd /home/ursus/ursus && git pull origin main && systemctl restart ursus
```

---

## ⚠️ Common Issues

**"Repository not found"?**
- Make sure repository is public on GitHub
- Or use SSH key instead of HTTPS

**"Permission denied" on deploy.sh?**
```bash
chmod +x /home/ursus/ursus/deploy.sh
sudo bash deploy.sh
```

**URSUS won't start?**
```bash
sudo bash /home/ursus/ursus/fix_deployment.sh
```

**Can't access config app?**
- Check firewall: `sudo ufw status`
- Check Nginx: `sudo systemctl status nginx`
- Allow port 5000: `sudo ufw allow 5000/tcp`

---

## 📞 Need Help?

- 📧 Email: contact@deskcodes.com
- 📞 Phone: +1 206-408-6213
- 🕐 Hours: Mon-Fri 9AM-6PM EST

---

**That's it! Your URSUS Stripe Connect Gateway is now live! 🚀**

