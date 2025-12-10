#!/bin/bash

# ====================================================
# URSUS - Automated Non-Interactive Deployment
# No questions asked - just runs with defaults
# ====================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  URSUS Automated Deployment"
echo "==========================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✘ Please run as root or with sudo${NC}"
    exit 1
fi

# No hardcoded domain/email - user will enter via dashboard!
# Create placeholder .env
cat > /tmp/initial_env << 'EOF'
# Server Configuration (will be set via dashboard)
DOMAIN=change-me.com
EMAIL=admin@change-me.com

# Stripe Configuration (will be set via dashboard)
STRIPE_SECRET_KEY=placeholder
STRIPE_WEBHOOK_SECRET=placeholder
CONNECTED_ACCOUNT_ID=placeholder

# Security
URSUS_API_KEY=auto-generated

# Application
FLASK_ENV=production
PORT=4242

# Business Names
PLATFORM_NAME=My Platform
CONNECTED_NAME=My Vendor
EOF

echo -e "${YELLOW}Configuration:${NC}"
echo "  All settings will be configured via web dashboard!"
echo "  Domain, Email, and Stripe keys → Dashboard at http://[server]:5000"
echo ""

# ====================================================
# Part 1: System Update
# ====================================================
echo -e "${BLUE}📦 Updating system packages...${NC}"
apt update && apt upgrade -y
apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git ufw fail2ban curl

# ====================================================
# Part 2: Create URSUS User
# ====================================================
echo -e "${BLUE}👤 Creating ursus user...${NC}"
if id "ursus" &>/dev/null; then
    echo -e "${YELLOW}⚠  User 'ursus' already exists${NC}"
else
    useradd -r -m -s /bin/bash ursus
    echo -e "${GREEN}✓ User 'ursus' created${NC}"
fi

# ====================================================
# Part 3: Configure Firewall
# ====================================================
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5000/tcp
echo -e "${GREEN}✓ Firewall configured${NC}"

# ====================================================
# Part 4: Deploy Application
# ====================================================
echo -e "${BLUE}📁 Deploying application...${NC}"

if [ -d "/home/ursus/ursus" ]; then
    echo -e "${YELLOW}Updating existing deployment...${NC}"
    cd /home/ursus/ursus
    git pull origin main
else
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/mohamederrajy/stripe-connect.git /home/ursus/ursus
fi

echo -e "${GREEN}✓ Files deployed${NC}"

# Set ownership
chown -R ursus:ursus /home/ursus/ursus

# ====================================================
# Part 5: Setup Virtual Environment
# ====================================================
echo -e "${BLUE}🐍 Setting up Python environment...${NC}"
su - ursus -c "cd /home/ursus/ursus && python3 -m venv venv"
su - ursus -c "cd /home/ursus/ursus && source venv/bin/activate && pip install --upgrade pip"
su - ursus -c "cd /home/ursus/ursus && source venv/bin/activate && pip install -r requirements.txt"
echo -e "${GREEN}✓ Python environment ready${NC}"

# ====================================================
# Part 6: Configure Environment
# ====================================================
echo -e "${BLUE}⚙️ Configuring environment...${NC}"

if [ ! -f "/home/ursus/ursus/.env" ]; then
    # Create .env with placeholders
    API_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    
    cat > /home/ursus/ursus/.env << ENVEOF
# Server Configuration (set via dashboard)
DOMAIN=example.com
EMAIL=admin@example.com

# Stripe Configuration (set via dashboard)
STRIPE_SECRET_KEY=placeholder
STRIPE_WEBHOOK_SECRET=placeholder
CONNECTED_ACCOUNT_ID=placeholder

# Security
URSUS_API_KEY=$API_KEY

# Application
FLASK_ENV=production
PORT=4242

# Business Names
PLATFORM_NAME=My Platform
CONNECTED_NAME=My Vendor
ENVEOF
    
    chown ursus:ursus /home/ursus/ursus/.env
    chmod 600 /home/ursus/ursus/.env
    
    echo -e "${GREEN}✓ Created .env with placeholders${NC}"
    echo -e "${YELLOW}⚠  Configure everything in the web dashboard!${NC}"
else
    echo -e "${YELLOW}⚠  .env already exists${NC}"
fi

# ====================================================
# Part 7: Create Systemd Service
# ====================================================
echo -e "${BLUE}⚙️ Creating systemd service...${NC}"

mkdir -p /var/log/ursus
chown ursus:ursus /var/log/ursus

cat > /etc/systemd/system/ursus.service << 'EOF'
[Unit]
Description=URSUS Stripe Connect Gateway
After=network.target

[Service]
Type=notify
User=ursus
Group=ursus
WorkingDirectory=/home/ursus/ursus
Environment="PATH=/home/ursus/ursus/venv/bin"
Environment="FLASK_ENV=production"

ExecStart=/home/ursus/ursus/venv/bin/gunicorn \
    --bind 127.0.0.1:4242 \
    --workers 4 \
    --threads 2 \
    --worker-class sync \
    --timeout 30 \
    --max-requests 1000 \
    --log-level info \
    --access-logfile /var/log/ursus/access.log \
    --error-logfile /var/log/ursus/error.log \
    app:app

Restart=always
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ursus
echo -e "${GREEN}✓ Systemd service created${NC}"

# ====================================================
# Part 8: Configure Nginx
# ====================================================
echo -e "${BLUE}🌐 Configuring Nginx...${NC}"

cat > /etc/nginx/sites-available/ursus << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://127.0.0.1:4242;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:4242;
        proxy_buffering off;
        access_log off;
    }

    location /webhook {
        proxy_pass http://127.0.0.1:4242;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        client_max_body_size 1M;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ursus /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx
echo -e "${GREEN}✓ Nginx configured${NC}"

# ====================================================
# Part 9: Obtain SSL Certificate
# ====================================================
echo -e "${BLUE}🔒 Obtaining SSL certificate...${NC}"

certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL certificate installed${NC}"
    systemctl reload nginx
else
    echo -e "${YELLOW}⚠  SSL certificate failed${NC}"
fi

# ====================================================
# Part 10: Setup Log Rotation
# ====================================================
echo -e "${BLUE}📋 Configuring log rotation...${NC}"

cat > /etc/logrotate.d/ursus << EOF
/var/log/ursus/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ursus ursus
    sharedscripts
    postrotate
        systemctl reload ursus > /dev/null 2>&1 || true
    endscript
}
EOF

echo -e "${GREEN}✓ Log rotation configured${NC}"

# ====================================================
# Part 11: Setup Fail2Ban
# ====================================================
echo -e "${BLUE}🛡️ Configuring Fail2Ban...${NC}"

cat > /etc/fail2ban/jail.local << EOF
[ursus-auth]
enabled = true
port = http,https
filter = ursus-auth
logpath = /var/log/ursus/error.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

cat > /etc/fail2ban/filter.d/ursus-auth.conf << EOF
[Definition]
failregex = ^.*Invalid API key attempt from <HOST>.*$
            ^.*API request without key from <HOST>.*$
ignoreregex =
EOF

systemctl restart fail2ban
echo -e "${GREEN}✓ Fail2Ban configured${NC}"

# ====================================================
# Part 12: Start URSUS
# ====================================================
echo -e "${BLUE}🚀 Starting URSUS service...${NC}"

systemctl start ursus
sleep 2

if systemctl is-active --quiet ursus; then
    echo -e "${GREEN}✓✓✓ URSUS is running!${NC}"
else
    echo -e "${RED}✘ URSUS failed to start${NC}"
    journalctl -u ursus -n 20
fi

# ====================================================
# Final Information
# ====================================================
echo ""
echo -e "${GREEN}=========================================="
echo "  ✓ Automated Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📊 Your URSUS Gateway URLs:${NC}"
echo ""
echo "  🌐 Configuration Dashboard:"
echo "     http://5.161.116.77:5000"
echo ""
echo "  🔗 API Endpoint:"
echo "     https://$DOMAIN/create-payment-intent"
echo ""
echo "  ✓ Health Check:"
echo "     https://$DOMAIN/health"
echo ""
echo "  🔔 Webhook:"
echo "     https://$DOMAIN/webhook"
echo ""
echo -e "${YELLOW}⚠️  NEXT STEP:${NC}"
echo ""
echo "1. Open in your browser:"
echo "   http://[your-server-ip]:5000"
echo ""
echo "2. Enter ALL configuration:"
echo "   • Domain Name (e.g., pay.yourdomain.com)"
echo "   • Email Address (e.g., admin@example.com)"
echo "   • STRIPE_SECRET_KEY (sk_live_...)"
echo "   • CONNECTED_ACCOUNT_ID (acct_...)"
echo "   • STRIPE_WEBHOOK_SECRET (whsec_...)"
echo "   • Platform Name (optional)"
echo "   • Vendor Name (optional)"
echo ""
echo "3. Click: Save Configuration"
echo ""
echo "4. Done! Your URSUS is live! 🎉"
echo ""
echo -e "${YELLOW}📞 Support:${NC}"
echo "  Email: contact@deskcodes.com"
echo "  Phone: +1 206-408-6213"
echo ""

