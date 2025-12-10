# 🚀 SIMPLE ONE-COMMAND DEPLOYMENT

Just run one command. Everything happens automatically. Then configure online!

---

## **The Easy Way (No Questions Asked)**

### **Step 1: SSH to Your Server**

```bash
ssh root@5.161.116.77
```

---

### **Step 2: One Command Deployment**

Copy and paste this **ONE LINE**:

```bash
cd /tmp && git clone https://github.com/mohamederrajy/stripe-connect.git && cd stripe-connect && chmod +x deploy_automated.sh && sudo bash deploy_automated.sh
```

**That's it!** The script will:
- ✅ Update system
- ✅ Install all dependencies
- ✅ Configure Nginx
- ✅ Setup SSL (auto)
- ✅ Start URSUS service
- ✅ Setup monitoring

**⏳ Takes ~10-15 minutes (fully automatic, no prompts!)**

---

### **Step 3: Wait for Completion**

Just wait for this message:
```
✓✓✓ URSUS is running!
```

---

### **Step 4: Open Web Dashboard**

On your **local computer**, open your browser:

```
http://5.161.116.77:5000
```

You'll see a **beautiful purple form**.

---

### **Step 5: Enter Your 3 Stripe Keys**

Fill in the form with:

1. **Stripe Secret Key** (sk_live_...)
   - From: Stripe Dashboard → Developers → API Keys
   
2. **Connected Account ID** (acct_...)
   - From: Stripe Dashboard → Connected Accounts
   
3. **Webhook Secret** (whsec_...)
   - From: Stripe Dashboard → Developers → Webhooks

---

### **Step 6: Click "Save Configuration"**

You'll see: **✓ Configuration saved successfully!**

---

### **Step 7: Your URSUS is LIVE!**

Your gateway is now online at:

- **Web Dashboard:** http://5.161.116.77:5000
- **API:** https://your-domain.com/create-payment-intent
- **Webhook:** https://your-domain.com/webhook
- **Health:** https://your-domain.com/health

---

## **If You Have a Domain**

After deployment, configure in Stripe Dashboard:

1. Go to **Stripe Dashboard**
2. Go to **Developers → Webhooks**
3. Update webhook URL to: `https://your-domain.com/webhook`
4. Events: `charge.succeeded`, `charge.captured`, `charge.refunded`

---

## **Useful Commands**

Once deployed, manage your URSUS with:

```bash
# Check status
sudo systemctl status ursus

# View logs
sudo journalctl -u ursus -f

# Restart
sudo systemctl restart ursus

# Stop
sudo systemctl stop ursus

# Start
sudo systemctl start ursus
```

---

## **Troubleshooting**

**"Can't access dashboard at :5000?"**
```bash
sudo ufw allow 5000/tcp
```

**"URSUS won't start?"**
```bash
sudo bash /home/ursus/ursus/fix_deployment.sh
```

**"Check what went wrong?"**
```bash
sudo journalctl -u ursus -n 50
```

---

## **Summary**

| Step | Action | Time |
|------|--------|------|
| 1 | SSH to server | 1 min |
| 2 | Run one deploy command | 10-15 min |
| 3 | Wait for "URSUS is running" | Auto |
| 4 | Open dashboard in browser | 1 min |
| 5 | Enter 3 Stripe keys | 2 min |
| 6 | Click Save | Auto |
| **Total** | **Everything Online** | **~20 min** |

---

## **After Deployment**

Your URSUS will:
- ✅ Accept payments 24/7
- ✅ Calculate fees automatically
- ✅ Transfer vendor shares
- ✅ Run forever (auto-restart)
- ✅ Log everything
- ✅ Monitor health

---

## **Support**

- 📧 contact@deskcodes.com
- 📞 +1 206-408-6213
- 🕐 Mon-Fri 9AM-6PM EST

---

**Ready? Run the deployment command and you're done!** 🎉

