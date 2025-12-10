# ⚡ URSUS - Stripe Connect Gateway v2.0

> **Automated revenue routing between Platform Account and Connected Account using Stripe Connect**

## 🎯 What is URSUS?

URSUS is a production-ready **Stripe Connect gateway service** that automatically:

✅ Accepts payments from customers on your **Platform Account**  
✅ Automatically calculates fees (Stripe + Platform commission)  
✅ Transfers vendor's share to **Connected Account** via webhook  
✅ Handles refunds (Platform absorbs cost as Merchant of Record)  
✅ Logs all transactions for accounting & compliance  
✅ Provides API for creating payments  
✅ Runs 24/7 with monitoring & auto-restart  

---

## 🏃 Quick Start (5 Minutes)

### 1. Get 3 Keys from Stripe

**You need:**
- `sk_live_...` (Secret API Key from Platform Account)
- `acct_...` (Connected Account ID of your vendor)
- `whsec_...` (Webhook Secret after creating webhook)

See **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** for detailed steps.

### 2. Run Configuration App

```bash
# On your machine or VPS
python3 config_app.py

# Then open: http://localhost:5000
```

### 3. Enter the 3 Keys

Paste your Stripe keys into the web form and click **Save Configuration**.

### 4. Restart URSUS

```bash
systemctl restart ursus
systemctl status ursus
```

### 5. Test It

```bash
curl https://your-domain.com/health
# Should return: {"status": "healthy", ...}
```

**Done! You're ready to accept payments.** 🎉

---

## 📊 How It Works

```
Customer Payment ($100)
    ↓
URSUS receives on Platform Account
    ↓
Stripe webhook fires (charge.succeeded)
    ↓
URSUS calculates:
  • Stripe fee: 2.9% + $0.30 = $3.20
  • Platform commission: 1% = $0.97
  • Vendor share: remainder = $95.83
    ↓
URSUS transfers $95.83 to Connected Account
    ↓
Vendor receives payment ✓
Platform keeps commission ✓
```

---

## 📁 Project Structure

```
ursus/
├── app.py                    # Main URSUS gateway (port 4242)
├── config_app.py             # Configuration manager (port 5000)
├── templates/
│   └── index.html            # Web configuration interface
├── requirements.txt          # Python dependencies
├── deploy.sh                 # Production deployment script
├── fix_deployment.sh         # Deployment troubleshooting
├── run_config.sh             # Config app launcher
│
├── DOCUMENTATION:
├── README.md                 # This file
├── SETUP_GUIDE.md            # Step-by-step setup instructions
├── QUICK_REFERENCE.txt       # Quick reference card
├── ARCHITECTURE.md           # System architecture & data flow
├── CONFIG_README.md          # Configuration app details
└── env.example               # Example environment variables
```

---

## 🔧 Configuration (3 Steps)

### Option A: Web Interface (Recommended)

```bash
python3 config_app.py
# Open: http://localhost:5000
```

### Option B: Manual Edit

```bash
nano /home/ursus/ursus/.env

# Add these 3 lines:
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
CONNECTED_ACCOUNT_ID=acct_...
```

### Option C: Environment Variables

```bash
export STRIPE_SECRET_KEY="sk_live_..."
export STRIPE_WEBHOOK_SECRET="whsec_..."
export CONNECTED_ACCOUNT_ID="acct_..."
python3 app.py
```

---

## 🚀 API Usage

### Create a Payment

```bash
curl -X POST https://your-domain.com/create-payment-intent \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 10000,
    "order_id": "ORD-123",
    "customer_email": "customer@example.com"
  }'
```

**Response:**
```json
{
  "client_secret": "pi_xxx_secret_xxx",
  "payment_intent_id": "pi_xxx",
  "amount": 10000,
  "fee_breakdown": {
    "stripe_fee": 320,
    "platform_commission": 97,
    "transfer_to_connected": 9583
  }
}
```

### Health Check

```bash
curl https://your-domain.com/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-10T15:30:00",
  "environment": "production",
  "stripe_connected": true
}
```

---

## 🛡️ Security Features

| Feature | Details |
|---------|---------|
| **API Key Authentication** | X-API-Key header validation |
| **Webhook Signature Verification** | Stripe signature checking (whsec_...) |
| **Rate Limiting** | 10/min for payments, 1000/hr for webhooks |
| **Input Validation** | Amount, email, order ID validation |
| **Idempotency Protection** | Prevents duplicate transfers |
| **Error Handling** | Secure messages, no stack traces |
| **Fail2Ban** | Automatic IP banning after 5 failed attempts |
| **SSL/TLS** | HTTPS with Certbot auto-renewal |
| **MoR Model** | Platform absorbs refund costs |

---

## 📋 Environment Variables

```env
# REQUIRED - Get from Stripe Dashboard
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
CONNECTED_ACCOUNT_ID=acct_...
URSUS_API_KEY=auto_generated_key

# OPTIONAL
FLASK_ENV=production              # or development
PORT=4242
PLATFORM_NAME=My Platform
CONNECTED_NAME=My Vendor
```

See **[env.example](./env.example)** for complete options.

---

## 🚢 Deployment

### Automatic (Recommended)

```bash
sudo bash deploy.sh
```

This installs everything:
- System packages
- Python environment
- Nginx reverse proxy
- SSL certificate
- Systemd service
- Log rotation
- Monitoring
- Fail2Ban

### Manual / Already Deployed?

```bash
sudo bash fix_deployment.sh
```

This troubleshoots and fixes any issues.

---

## 📊 Monitoring & Logs

### View Service Status
```bash
systemctl status ursus
```

### View Live Logs
```bash
journalctl -u ursus -f
```

### View Error Log
```bash
tail -f /var/log/ursus/error.log
```

### View Access Log
```bash
tail -f /var/log/ursus/access.log
```

### Health Check
```bash
curl https://your-domain.com/health
```

### Cron Monitoring (Every 5 min)
Automatic monitoring of:
- Service health
- Disk usage
- Memory usage
- Auto-restart on failure

---

## 🔄 Payment Flow Diagram

```
Customer                Platform Account         Connected Account
   │                         │                          │
   │  1. Pays $100           │                          │
   ├────────────────────────▶│                          │
   │                         │                          │
   │                    2. charge.succeeded            │
   │                      webhook event                │
   │                         │                          │
   │                    3. Calculate fees:            │
   │                       - Stripe: $3.20            │
   │                       - Platform: $0.97          │
   │                       - Vendor: $95.83           │
   │                         │                          │
   │                    4. Create transfer            │
   │                         ├─────────────────────────▶│
   │                         │                          │
   │                         │          5. Receive: $95.83 ✓
   │                         │                          │
   │                    Keep: $4.17                   │
   │                    ($3.20 + $0.97)               │
```

---

## 🆘 Troubleshooting

### Service won't start?
```bash
journalctl -u ursus -n 50 --no-pager
sudo bash fix_deployment.sh
```

### Can't find Stripe keys?
See **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** → "How to Get Each Key"

### Webhook not firing?
1. Check webhook URL is correct in Stripe Dashboard
2. Check you selected the right events
3. View logs: `tail -f /var/log/ursus/error.log`

### Configuration app not working?
```bash
# Make sure Flask is installed
pip install flask python-dotenv

# Run with debug
python3 config_app.py
```

---

## 📞 Support

### DeskCodes
- **Phone:** +1 206-408-6213
- **Email:** contact@deskcodes.com
- **Address:** 182-21 150th Avenue, Springfield Gardens NY 11413
- **Hours:** Mon-Fri: 9AM-6PM EST

### Documentation
- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Complete setup instructions
- [QUICK_REFERENCE.txt](./QUICK_REFERENCE.txt) - Quick commands
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [CONFIG_README.md](./CONFIG_README.md) - Configuration app docs

---

## 📈 Features

### Payment Processing
- ✅ Create PaymentIntents via API
- ✅ Support all payment methods
- ✅ Custom order IDs
- ✅ Customer email receipts
- ✅ Metadata support

### Automatic Transfers
- ✅ Real-time fund distribution
- ✅ Webhook-based automation
- ✅ Idempotency protection
- ✅ Refund handling

### Monitoring
- ✅ Health check endpoint
- ✅ Detailed logging
- ✅ Error tracking
- ✅ Performance monitoring
- ✅ Cron health checks

### Security
- ✅ API key authentication
- ✅ Webhook signature verification
- ✅ Rate limiting
- ✅ Input validation
- ✅ Fail2Ban protection
- ✅ SSL/TLS encryption
- ✅ Secure error messages

### Operations
- ✅ Auto-restart on crash
- ✅ Log rotation
- ✅ Systemd integration
- ✅ Production-ready
- ✅ Scalable architecture

---

## 🔐 Security Best Practices

1. **Never commit `.env` file** to git
2. **Use `sk_live_` in production**, not `sk_test_`
3. **Rotate API keys** periodically
4. **Monitor logs** for suspicious activity
5. **Keep dependencies updated**: `pip install --upgrade stripe flask gunicorn`
6. **Use strong webhook URLs** with HTTPS
7. **Verify sender** IP addresses if possible
8. **Enable 2FA** on your Stripe account

---

## 📊 Version Info

```
╔════════════════════════════════════════╗
║     URSUS v2.0 - Production Ready      ║
║                                        ║
║  • Stripe Connect Gateway              ║
║  • Automated Revenue Routing           ║
║  • 24/7 Uptime Ready                   ║
║  • Enterprise Grade Security           ║
║  • Beautiful Configuration UI          ║
║                                        ║
║  Built with Flask + Stripe SDK         ║
║  Deployed with Nginx + Gunicorn        ║
║  Monitored with Systemd + Fail2Ban     ║
╚════════════════════════════════════════╝
```

---

## 📜 License & Support

URSUS is provided as-is for your Stripe Connect payment processing needs.

For issues, questions, or feature requests:
- 📧 Email: contact@deskcodes.com
- 📞 Phone: +1 206-408-6213

---

## 🎉 Ready to Go!

Your URSUS gateway is **production-ready** and waiting for you to configure it.

**Next steps:**
1. Read **[SETUP_GUIDE.md](./SETUP_GUIDE.md)**
2. Get your Stripe keys
3. Run `python3 config_app.py`
4. Save configuration
5. Restart: `systemctl restart ursus`
6. Test: `curl https://your-domain.com/health`
7. Accept payments! 💰

---

Made with ❤️ for seamless payment processing.

