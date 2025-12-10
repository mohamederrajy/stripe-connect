# ✅ URSUS Deployment Checklist

Use this checklist to ensure your URSUS deployment is complete and working.

---

## 📋 Pre-Deployment

- [ ] Have Ubuntu 22.04+ VPS with root access
- [ ] Have Stripe account with Platform Account
- [ ] Have Stripe account with Connected Account (vendor)
- [ ] Have a domain name (e.g., pay.yourdomain.com)
- [ ] Domain DNS is pointing to your VPS
- [ ] Port 80 (HTTP) and 443 (HTTPS) are open
- [ ] SSH access to your VPS

---

## 🔑 Stripe Configuration

- [ ] **Stripe Secret Key** (sk_live_...)
  - [ ] Located in Stripe Dashboard → Developers → API Keys
  - [ ] Copied the **Secret Key** (not Publishable Key)
  - [ ] Format verified (starts with `sk_live_` or `sk_test_`)

- [ ] **Connected Account ID** (acct_...)
  - [ ] Located in Stripe Dashboard → Connected Accounts
  - [ ] Identified vendor's Stripe account
  - [ ] Copied the **Account ID**
  - [ ] Format verified (starts with `acct_`)

- [ ] **Webhook Configuration**
  - [ ] Created webhook in Stripe Dashboard → Developers → Webhooks
  - [ ] Endpoint URL: `https://your-domain.com/webhook`
  - [ ] Selected events:
    - [ ] `charge.succeeded`
    - [ ] `charge.captured`
    - [ ] `charge.refunded`
  - [ ] Copied **Signing secret** (whsec_...)
  - [ ] Format verified (starts with `whsec_`)

---

## 🚀 Deployment Steps

- [ ] **SSH into server**
  ```bash
  ssh root@your-server.com
  ```

- [ ] **Run deployment script**
  ```bash
  cd /path/to/ursus
  sudo bash deploy.sh
  ```

- [ ] **Answer deployment prompts**
  - [ ] Enter domain name
  - [ ] Enter email for SSL certificate
  - [ ] Confirm configuration

- [ ] **Verify deployment completed**
  - [ ] All files copied to `/home/ursus/ursus/`
  - [ ] Virtual environment created
  - [ ] Dependencies installed
  - [ ] Nginx configured
  - [ ] SSL certificate obtained
  - [ ] Systemd service created
  - [ ] Log rotation configured
  - [ ] Fail2Ban configured

---

## ⚙️ Configuration

- [ ] **Method A: Web Interface (Recommended)**
  ```bash
  # On your VPS
  cd /home/ursus/ursus
  source venv/bin/activate
  python3 config_app.py
  
  # Then visit: http://your-vps-ip:5000
  ```

  - [ ] Opened configuration app in browser
  - [ ] Entered Stripe Secret Key
  - [ ] Entered Connected Account ID
  - [ ] Entered Webhook Secret
  - [ ] Optionally entered Platform Name
  - [ ] Optionally entered Connected Account Name
  - [ ] Clicked **Save Configuration**
  - [ ] Saw success message

- [ ] **Method B: Manual .env Edit (If needed)**
  ```bash
  sudo nano /home/ursus/ursus/.env
  ```

  - [ ] Updated `STRIPE_SECRET_KEY=`
  - [ ] Updated `STRIPE_WEBHOOK_SECRET=`
  - [ ] Updated `CONNECTED_ACCOUNT_ID=`
  - [ ] Saved file (Ctrl+X → Y → Enter)
  - [ ] Verified changes: `cat /home/ursus/ursus/.env`

---

## 🔍 Verification Steps

- [ ] **Restart URSUS service**
  ```bash
  sudo systemctl restart ursus
  ```

- [ ] **Check service status**
  ```bash
  sudo systemctl status ursus
  ```
  - [ ] Status shows "active (running)"
  - [ ] No error messages
  - [ ] Restart count is 0 or low

- [ ] **Test health endpoint**
  ```bash
  curl https://your-domain.com/health
  ```
  - [ ] Returns HTTP 200
  - [ ] Response shows `"status": "healthy"`
  - [ ] Shows `"stripe_connected": true`

- [ ] **Check logs for errors**
  ```bash
  sudo journalctl -u ursus -n 50 --no-pager
  ```
  - [ ] No ERROR messages
  - [ ] No CRITICAL messages
  - [ ] Shows service startup messages

- [ ] **View error log**
  ```bash
  sudo tail -20 /var/log/ursus/error.log
  ```
  - [ ] File exists
  - [ ] No recent errors

- [ ] **Verify configuration saved**
  ```bash
  sudo cat /home/ursus/ursus/.env | grep STRIPE
  ```
  - [ ] `STRIPE_SECRET_KEY` is set (not placeholder)
  - [ ] `STRIPE_WEBHOOK_SECRET` is set (not placeholder)
  - [ ] `CONNECTED_ACCOUNT_ID` is set (not placeholder)

---

## 🧪 Functionality Tests

- [ ] **Test SSL certificate**
  ```bash
  curl -I https://your-domain.com/health
  ```
  - [ ] Returns HTTP 200
  - [ ] Shows "SSL certificate verify ok" (or similar)

- [ ] **Test API endpoint**
  ```bash
  curl -X POST https://your-domain.com/create-payment-intent \
    -H "X-API-Key: wrong-key" \
    -H "Content-Type: application/json" \
    -d '{"amount": 10000}'
  ```
  - [ ] Returns 401 Unauthorized (expected with wrong key)
  - [ ] Message: "Invalid API key"

- [ ] **Test rate limiting** (if curious)
  ```bash
  # Run curl multiple times quickly
  for i in {1..15}; do curl https://your-domain.com/health; done
  ```
  - [ ] Eventually returns 429 (rate limit)

- [ ] **Monitor active connections**
  ```bash
  sudo ss -tlnp | grep 4242
  ```
  - [ ] Shows gunicorn listening on 127.0.0.1:4242

---

## 🔐 Security Checks

- [ ] **Firewall is configured**
  ```bash
  sudo ufw status
  ```
  - [ ] Shows: `Status: active`
  - [ ] SSH (22), HTTP (80), HTTPS (443) allowed

- [ ] **Fail2Ban is running**
  ```bash
  sudo systemctl status fail2ban
  ```
  - [ ] Shows: `active (running)`

- [ ] **.env file has restricted permissions**
  ```bash
  ls -la /home/ursus/ursus/.env
  ```
  - [ ] Shows: `-rw-------` or `600` (only owner can read)
  - [ ] Owner is `ursus`

- [ ] **API key is not in logs**
  ```bash
  sudo grep -r "sk_live" /var/log/ursus/ || echo "Good - not in logs"
  ```
  - [ ] Should say "Good - not in logs"

- [ ] **No debug mode in production**
  ```bash
  grep FLASK_ENV /home/ursus/ursus/.env
  ```
  - [ ] Should show: `FLASK_ENV=production`

---

## 📊 Monitoring Setup

- [ ] **Log rotation is configured**
  ```bash
  sudo cat /etc/logrotate.d/ursus
  ```
  - [ ] File exists and has content

- [ ] **Cron monitoring is running**
  ```bash
  sudo crontab -l
  ```
  - [ ] Shows entry for `ursus-monitor.sh`
  - [ ] Shows `*/5 * * * *` (every 5 minutes)

- [ ] **Monitor script is executable**
  ```bash
  ls -la /usr/local/bin/ursus-monitor.sh
  ```
  - [ ] Shows `x` permission (executable)

---

## 🔄 Deployment Fix (If needed)

If anything is not working, run:

```bash
cd /home/ursus/ursus
sudo bash fix_deployment.sh
```

- [ ] **Fix script completed successfully**
  - [ ] Virtual environment verified/fixed
  - [ ] Gunicorn installation verified/fixed
  - [ ] Permissions fixed
  - [ ] app.py validated
  - [ ] Systemd service recreated
  - [ ] Service started
  - [ ] Status shows "running"

---

## ✅ Final Verification

- [ ] **Health check passes**
  ```bash
  curl https://your-domain.com/health | jq .
  ```

- [ ] **Service auto-restarts on failure**
  ```bash
  sudo systemctl kill ursus
  sleep 2
  sudo systemctl status ursus
  ```
  - [ ] Service automatically restarted

- [ ] **Logs are rotating**
  ```bash
  ls -la /var/log/ursus/
  ```
  - [ ] Multiple `.log` files present
  - [ ] Recent modification times

- [ ] **System resources are healthy**
  ```bash
  free -h  # Memory
  df -h    # Disk
  ```

---

## 📞 Ready for Production

Once all checkboxes are marked:

✅ **URSUS is ready to accept payments!**

### Quick Commands Reference

```bash
# Check status
sudo systemctl status ursus

# View logs
sudo journalctl -u ursus -f

# Restart service
sudo systemctl restart ursus

# Check health
curl https://your-domain.com/health

# View configuration
sudo cat /home/ursus/ursus/.env

# Check Stripe connectivity
sudo journalctl -u ursus | grep "Stripe"
```

### Support Contact

If you encounter any issues:
- 📧 Email: contact@deskcodes.com
- 📞 Phone: +1 206-408-6213
- 🕐 Hours: Mon-Fri 9AM-6PM EST

---

## 🎉 Deployment Complete!

Your URSUS Stripe Connect Gateway is now live and ready to process payments.

**Congratulations!** 🚀

