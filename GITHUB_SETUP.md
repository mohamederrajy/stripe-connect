# 📤 Push URSUS to GitHub & Deploy to Server

Complete guide to push your URSUS project to GitHub and deploy it to your server.

---

## Part 1: Push to GitHub

### Step 1: Initialize Git & Add Remote

```bash
cd ~/Documents/ursus

# Initialize git repository (if not already done)
git init

# Add your GitHub repository
git remote add origin https://github.com/mohamederrajy/stripe-connect.git

# Or if remote already exists, update it:
git remote set-url origin https://github.com/mohamederrajy/stripe-connect.git

# Verify the remote
git remote -v
```

### Step 2: Configure Git (First Time Only)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Step 3: Add All Files

```bash
# Add all files to staging
git add .

# Check what will be committed
git status
```

### Step 4: Create Initial Commit

```bash
git commit -m "Initial URSUS v2.0 - Stripe Connect Gateway with Configuration System"
```

### Step 5: Push to GitHub

```bash
# Push to main branch
git branch -M main
git push -u origin main

# If you get authentication errors, use:
# - Personal Access Token (recommended)
# - Or SSH key (if configured)
```

### Step 6: Verify on GitHub

- Go to: https://github.com/mohamederrajy/stripe-connect
- You should see all files pushed ✓

---

## Part 2: Deploy to Your Server

Your server: **5.161.116.77**

### Step 1: Connect to Your Server

```bash
ssh root@5.161.116.77

# Enter your server password/key when prompted
```

### Step 2: Clone from GitHub

```bash
# Clone your repository
git clone https://github.com/mohamederrajy/stripe-connect.git /home/ursus/ursus

# Or if it already exists:
cd /home/ursus/ursus
git pull origin main
```

### Step 3: Run the Deployment Script

```bash
cd /home/ursus/ursus

# Make script executable
chmod +x deploy.sh

# Run deployment (interactive)
sudo bash deploy.sh
```

The script will:
- ✓ Update system packages
- ✓ Create 'ursus' user
- ✓ Configure firewall
- ✓ Install Python & dependencies
- ✓ Set up virtual environment
- ✓ Configure Nginx
- ✓ Obtain SSL certificate
- ✓ Create systemd service
- ✓ Setup monitoring

### Step 4: Configure Your 3 Stripe Keys

**Option A: Web Interface (Recommended)**
```bash
# On your server, after deployment
cd /home/ursus/ursus
source venv/bin/activate
python3 config_app.py

# Then visit: http://5.161.116.77:5000 in your browser
# Enter your 3 Stripe keys and save
```

**Option B: Manual .env Edit**
```bash
sudo nano /home/ursus/ursus/.env

# Add your 3 keys:
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
CONNECTED_ACCOUNT_ID=acct_...

# Save: Ctrl+X → Y → Enter
```

### Step 5: Restart & Test

```bash
# Restart URSUS service
sudo systemctl restart ursus

# Check status
sudo systemctl status ursus

# Test health endpoint
curl https://5.161.116.77/health

# View logs
sudo journalctl -u ursus -f
```

---

## .gitignore Configuration

Create `.gitignore` file to prevent committing sensitive files:

```bash
cat > /Users/aziz/Documents/ursus/.gitignore << 'EOF'
# Environment variables (NEVER commit!)
.env
.env.local
.env.*.local

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
logs/
*.pid

# OS
.DS_Store
Thumbs.db

# Virtual environments
venv/
env/
ENV/

# Testing
.pytest_cache/
.coverage
htmlcov/

# Local development
.env.local
local_settings.py
EOF
```

---

## Quick Command Reference

### Git Commands

```bash
# Check status
git status

# Add all changes
git add .

# Commit
git commit -m "Your message"

# Push to GitHub
git push origin main

# Pull latest
git pull origin main

# View log
git log --oneline -10

# Revert a file
git checkout -- filename
```

### Server Commands

```bash
# SSH into server
ssh root@5.161.116.77

# Clone repository
git clone https://github.com/mohamederrajy/stripe-connect.git /home/ursus/ursus

# Check URSUS status
sudo systemctl status ursus

# View logs
sudo journalctl -u ursus -f

# Restart service
sudo systemctl restart ursus

# Test health
curl https://5.161.116.77/health

# Check config
sudo cat /home/ursus/ursus/.env

# Run config app
cd /home/ursus/ursus && source venv/bin/activate && python3 config_app.py
```

---

## Troubleshooting

**"Permission denied" when pushing?**
- Use Personal Access Token instead of password
- Or setup SSH keys

**GitHub says "repository is empty"?**
- That's normal for new repo
- Your push should populate it

**Deployment script fails?**
- Run: `sudo bash fix_deployment.sh`
- Check logs: `sudo journalctl -u ursus -f`

**Server unreachable?**
- Check firewall: `sudo ufw status`
- Check Nginx: `sudo systemctl status nginx`
- Check URSUS: `sudo systemctl status ursus`

---

## Summary

**Local (Your Computer):**
1. `git init` - Initialize git
2. `git add .` - Add all files
3. `git commit -m "message"` - Commit
4. `git push -u origin main` - Push to GitHub

**Server (5.161.116.77):**
1. `ssh root@5.161.116.77` - Connect
2. `git clone https://github.com/mohamederrajy/stripe-connect.git /home/ursus/ursus` - Clone
3. `cd /home/ursus/ursus && sudo bash deploy.sh` - Deploy
4. Configure Stripe keys
5. Test: `curl https://5.161.116.77/health`

---

## After Deployment

Your URSUS gateway will be live at:
- **Web Interface:** https://5.161.116.77
- **API Endpoint:** https://5.161.116.77/create-payment-intent
- **Webhook Endpoint:** https://5.161.116.77/webhook
- **Health Check:** https://5.161.116.77/health

Configure webhook in Stripe Dashboard:
- **URL:** https://5.161.116.77/webhook
- **Events:** charge.succeeded, charge.captured, charge.refunded

---

**Done!** Your URSUS Stripe Connect Gateway is now live! 🚀

