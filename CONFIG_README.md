# 🔧 URSUS Configuration Manager

A simple web interface to configure your URSUS Stripe Connect Gateway with the 3 required keys.

## 🚀 Quick Start

### Development (Local Machine)

```bash
# Install dependencies
pip install flask python-dotenv

# Run the config app
python3 config_app.py
```

Then open your browser to **http://localhost:5000**

### Production (Ubuntu VPS)

```bash
# SSH into your server
ssh root@your-server.com

# Navigate to URSUS directory
cd /home/ursus/ursus

# Activate virtual environment
source venv/bin/activate

# Run the config app
python3 config_app.py
```

Then open your browser to **http://your-server-ip:5000**

> **Note:** The config manager runs on port 5000. After configuration, restart URSUS with:
> ```bash
> systemctl restart ursus
> ```

---

## 📋 What You'll Configure

### 1. **Stripe Secret Key** (required)
   - **Format:** `sk_live_xxxxx...` or `sk_test_xxxxx...`
   - **Get it from:** [Stripe Dashboard](https://dashboard.stripe.com) → Developers → API Keys
   - **It is:** Your Platform Account's secret API key

### 2. **Connected Account ID** (required)
   - **Format:** `acct_xxxxx...`
   - **Get it from:** [Stripe Dashboard](https://dashboard.stripe.com) → Connected Accounts
   - **It is:** The vendor/merchant Stripe account that receives payments

### 3. **Webhook Secret** (required)
   - **Format:** `whsec_xxxxx...`
   - **Get it from:** [Stripe Dashboard](https://dashboard.stripe.com) → Developers → Webhooks
   - **How to get it:**
     1. Click "Add an endpoint"
     2. URL: `https://your-domain.com/webhook`
     3. Select events: `charge.succeeded`, `charge.captured`, `charge.refunded`
     4. Copy the "Signing secret" (whsec_...)

---

## 🎨 Interface Features

✅ Clean, modern UI  
✅ Real-time validation  
✅ Format checking (sk_, acct_, whsec_)  
✅ Success/error alerts  
✅ Works on mobile  
✅ Responsive design  

---

## 📁 Files

- **config_app.py** - Flask backend that saves to `.env`
- **templates/index.html** - Modern web interface
- **run_config.sh** - Easy launcher script

---

## 🔐 Security

The configuration app:
- ✅ Hides passwords (uses password input fields)
- ✅ Validates all inputs before saving
- ✅ Only runs on localhost during development
- ✅ Requires you to input valid Stripe keys (format checking)

---

## 🐛 Troubleshooting

**"Address already in use" on port 5000?**
```bash
# Kill the process using port 5000
lsof -i :5000
kill -9 <PID>
```

**Can't find your Stripe keys?**
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Make sure you're in the right account (toggle at top left)
3. Click **Developers** tab → **API Keys**
4. Copy the **Secret Key** (not Publishable Key)

**Webhook setup error?**
1. Go to **Developers** → **Webhooks**
2. Click **Add an endpoint**
3. Fill in your domain: `https://yourdomain.com/webhook`
4. Check the events: `charge.succeeded`, `charge.captured`, `charge.refunded`
5. Copy the signing secret

---

## 💾 After Configuration

Once you've entered the 3 keys and clicked "Save Configuration":

```bash
# Restart the URSUS service
systemctl restart ursus

# Check if it's running
systemctl status ursus

# View logs
journalctl -u ursus -f
```

---

## 📞 Need Help?

**DeskCodes Support:**
- Phone: +1 206-408-6213
- Email: contact@deskcodes.com
- Hours: Mon-Fri 9AM-6PM EST

