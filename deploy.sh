#!/bin/bash

# ====================================================
# URSUS - Production Deployment Script
# ====================================================
# This script automates URSUS deployment on Ubuntu 22.04+ VPS
# Run as root or with sudo

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "  URSUS Production Deployment"
echo "==========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✘ Please run as root or with sudo${NC}"
    exit 1
fi

# Get domain
read -p "Enter your domain (e.g., pay.yourdomain.com): " DOMAIN
read -p "Enter email for SSL certificate: " EMAIL

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Domain: $DOMAIN"
echo "  Email: $EMAIL"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

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
echo -e "${GREEN}✓ Firewall configured${NC}"

# ====================================================
# Part 4: Deploy Application
# ====================================================
echo -e "${BLUE}📁 Deploying application...${NC}"

# Get the directory where the script is running from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${YELLOW}Script running from: $SCRIPT_DIR${NC}"

# Check if already deployed to /home/ursus/ursus
if [ -d "/home/ursus/ursus" ]; then
    echo -e "${YELLOW}⚠  /home/ursus/ursus already exists${NC}"
    read -p "Delete and redeploy? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf /home/ursus/ursus
    else
        echo -e "${RED}Aborting - /home/ursus/ursus already exists${NC}"
        exit 1
    fi
fi

# Copy files from current directory to /home/ursus/ursus
echo -e "${BLUE}Copying files from $SCRIPT_DIR to /home/ursus/ursus...${NC}"
mkdir -p /home/ursus/ursus

# Copy all files INCLUDING hidden files (dotfiles)
shopt -s dotglob  # Enable dotglob to include hidden files
cp -r "$SCRIPT_DIR"/* /home/ursus/ursus/ 2>/dev/null || true
cp -r "$SCRIPT_DIR"/.* /home/ursus/ursus/ 2>/dev/null || true
shopt -u dotglob  # Disable dotglob

# Remove . and .. if they got copied
rm -rf /home/ursus/ursus/. /home/ursus/ursus/.. 2>/dev/null || true

# Verify files were copied
if [ ! -f "/home/ursus/ursus/app.py" ]; then
    echo -e "${RED}✘ Error: app.py not found after copy!${NC}"
    echo -e "${RED}Make sure you're running this script from the URSUS directory${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Files copied successfully${NC}"

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
    # Check if .env.example exists
    if [ -f "/home/ursus/ursus/.env.example" ]; then
        cp /home/ursus/ursus/.env.example /home/ursus/ursus/.env
        echo -e "${GREEN}✓ Created .env from .env.example${NC}"
    else
        # Create .env from scratch if .env.example is missing
        echo -e "${YELLOW}⚠  .env.example not found, creating .env manually${NC}"
        cat > /home/ursus/ursus/.env << 'ENVEOF'
# Stripe Configuration
STRIPE_SECRET_KEY=sk_live_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
CONNECTED_ACCOUNT_ID=acct_your_connected_account

# Security
URSUS_API_KEY=generate_random_key_here

# Application
FLASK_ENV=production
PORT=4242

# Optional
PLATFORM_NAME=Platform Account
CONNECTED_NAME=Connected Account
ENVEOF
        echo -e "${GREEN}✓ Created basic .env file${NC}"
    fi
    
    # Generate API key
    API_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    sed -i "s/URSUS_API_KEY=.*/URSUS_API_KEY=$API_KEY/" /home/ursus/ursus/.env
    sed -i "s/FLASK_ENV=.*/FLASK_ENV=production/" /home/ursus/ursus/.env
    
    chown ursus:ursus /home/ursus/ursus/.env
    chmod 600 /home/ursus/ursus/.env
    
    echo -e "${YELLOW}⚠  IMPORTANT: Edit /home/ursus/ursus/.env and add your Stripe keys!${NC}"
    echo -e "${YELLOW}   Generated API Key: $API_KEY${NC}"
    echo -e "${YELLOW}   Save this key securely!${NC}"
else
    echo -e "${YELLOW}⚠  .env already exists${NC}"
fi

# ====================================================
# Part 7: Create Systemd Service
# ====================================================
echo -e "${BLUE}⚙️ Creating systemd service...${NC}"

# Create log directory
mkdir -p /var/log/ursus
chown ursus:ursus /var/log/ursus

# Create service file
cat > /etc/systemd/system/ursus.service << EOF
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
    --max-requests-jitter 50 \
    --log-level info \
    --access-logfile /var/log/ursus/access.log \
    --error-logfile /var/log/ursus/error.log \
    --capture-output \
    app:app

Restart=always
RestartSec=10
StartLimitInterval=0

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/ursus

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable ursus
echo -e "${GREEN}✓ Systemd service created${NC}"

# ====================================================
# Part 8: Configure Nginx
# ====================================================
echo -e "${BLUE}🌐 Configuring Nginx...${NC}"

# Create nginx config WITHOUT SSL first (we'll add SSL after certbot)
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

# Enable site
ln -sf /etc/nginx/sites-available/ursus /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx config
nginx -t
echo -e "${GREEN}✓ Nginx configured (HTTP only for now)${NC}"

# ====================================================
# Part 9: Obtain SSL Certificate
# ====================================================
echo -e "${BLUE}🔒 Obtaining SSL certificate...${NC}"

# Start nginx first
systemctl reload nginx

# Get certificate
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL certificate installed${NC}"
    
    # Certbot automatically updates nginx config with SSL
    # Reload nginx to apply changes
    systemctl reload nginx
else
    echo -e "${RED}✘ SSL certificate failed${NC}"
    echo -e "${YELLOW}You can get it manually later with: certbot --nginx -d $DOMAIN${NC}"
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
# Part 12: Setup Monitoring
# ====================================================
echo -e "${BLUE}📊 Setting up monitoring...${NC}"

cat > /usr/local/bin/ursus-monitor.sh << 'EOF'
#!/bin/bash
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://DOMAIN_PLACEHOLDER/health)
if [ "$HTTP_CODE" != "200" ]; then
    echo "$(date): ALERT - URSUS health check failed (HTTP $HTTP_CODE)"
    systemctl restart ursus
fi

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "$(date): ALERT - Disk usage is at ${DISK_USAGE}%"
fi

MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$MEM_USAGE" -gt 90 ]; then
    echo "$(date): ALERT - Memory usage is at ${MEM_USAGE}%"
fi
EOF

sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" /usr/local/bin/ursus-monitor.sh
chmod +x /usr/local/bin/ursus-monitor.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/ursus-monitor.sh >> /var/log/ursus/monitor.log 2>&1") | crontab -

echo -e "${GREEN}✓ Monitoring configured${NC}"

# ====================================================
# Part 13: Start URSUS
# ====================================================
echo -e "${BLUE}🚀 Starting URSUS...${NC}"

# Don't start yet - user needs to configure .env first
echo -e "${YELLOW}⚠  Service NOT started yet - configure .env first!${NC}"

# ====================================================
# Final Instructions
# ====================================================
echo ""
echo -e "${GREEN}=========================================="
echo "  ✓ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo ""
echo "1. Configure Stripe keys:"
echo "   nano /home/ursus/ursus/.env"
echo ""
echo "2. Add these values:"
echo "   - STRIPE_SECRET_KEY (sk_live_...)"
echo "   - STRIPE_WEBHOOK_SECRET (get after step 4)"
echo "   - CONNECTED_ACCOUNT_ID (acct_...)"
echo ""
echo "3. Start URSUS:"
echo "   systemctl start ursus"
echo "   systemctl status ursus"
echo ""
echo "4. Configure Stripe webhook:"
echo "   URL: https://$DOMAIN/webhook"
echo "   Events: charge.succeeded, charge.refunded"
echo ""
echo "5. Test deployment:"
echo "   curl https://$DOMAIN/health"
echo ""
echo -e "${BLUE}📊 Useful Commands:${NC}"
echo "   View logs:    journalctl -u ursus -f"
echo "   Restart:      systemctl restart ursus"
echo "   Check status: systemctl status ursus"
echo ""
echo -e "${GREEN}🎉 Your URSUS gateway is ready at: https://$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Generated API Key: $API_KEY${NC}"
echo -e "${YELLOW}Save this key securely - you'll need it for API calls!${NC}"
echo ""