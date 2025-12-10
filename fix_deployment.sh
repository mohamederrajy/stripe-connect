#!/bin/bash

# ====================================================
# URSUS - Deployment Fix Script
# ====================================================
# Run this to diagnose and fix the systemd service issue

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  URSUS Deployment Troubleshoot & Fix"
echo "==========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}✘ Please run as root or with sudo${NC}"
    exit 1
fi

# ====================================================
# Step 1: Check if virtual environment exists
# ====================================================
echo -e "${BLUE}1. Checking virtual environment...${NC}"

if [ ! -d "/home/ursus/ursus/venv" ]; then
    echo -e "${RED}✘ Virtual environment not found!${NC}"
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    su - ursus -c "cd /home/ursus/ursus && python3 -m venv venv"
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment exists${NC}"
fi

# ====================================================
# Step 2: Check if gunicorn is installed
# ====================================================
echo -e "${BLUE}2. Checking gunicorn installation...${NC}"

if [ ! -f "/home/ursus/ursus/venv/bin/gunicorn" ]; then
    echo -e "${RED}✘ Gunicorn not found in virtual environment!${NC}"
    echo -e "${YELLOW}Installing dependencies...${NC}"
    su - ursus -c "cd /home/ursus/ursus && source venv/bin/activate && pip install --upgrade pip"
    su - ursus -c "cd /home/ursus/ursus && source venv/bin/activate && pip install -r requirements.txt"
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${GREEN}✓ Gunicorn is installed${NC}"
fi

# Verify gunicorn is executable
if [ -x "/home/ursus/ursus/venv/bin/gunicorn" ]; then
    echo -e "${GREEN}✓ Gunicorn is executable${NC}"
else
    echo -e "${YELLOW}⚠ Making gunicorn executable...${NC}"
    chmod +x /home/ursus/ursus/venv/bin/gunicorn
fi

# ====================================================
# Step 3: Check file permissions
# ====================================================
echo -e "${BLUE}3. Checking file permissions...${NC}"

chown -R ursus:ursus /home/ursus/ursus
chown -R ursus:ursus /var/log/ursus
chmod +x /home/ursus/ursus/venv/bin/*
echo -e "${GREEN}✓ Permissions fixed${NC}"

# ====================================================
# Step 4: Verify app.py exists and is valid
# ====================================================
echo -e "${BLUE}4. Checking app.py...${NC}"

if [ ! -f "/home/ursus/ursus/app.py" ]; then
    echo -e "${RED}✘ app.py not found!${NC}"
    exit 1
fi

# Test if Python can at least import the file
su - ursus -c "cd /home/ursus/ursus && source venv/bin/activate && python3 -c 'import app'" 2>&1 | tee /tmp/ursus_test.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ app.py is valid${NC}"
else
    echo -e "${RED}✘ app.py has errors. Check /tmp/ursus_test.log${NC}"
    cat /tmp/ursus_test.log
    exit 1
fi

# ====================================================
# Step 5: Test gunicorn manually
# ====================================================
echo -e "${BLUE}5. Testing gunicorn manually...${NC}"

# Try to run gunicorn for 2 seconds to see if it starts
timeout 2 su - ursus -c "cd /home/ursus/ursus && source venv/bin/activate && gunicorn --bind 127.0.0.1:4242 app:app" 2>&1 | head -20 || true

if [ $? -eq 124 ]; then
    echo -e "${GREEN}✓ Gunicorn can start (timeout is expected)${NC}"
else
    echo -e "${YELLOW}⚠ Check the output above for errors${NC}"
fi

# ====================================================
# Step 6: Recreate systemd service with better config
# ====================================================
echo -e "${BLUE}6. Recreating systemd service...${NC}"

cat > /etc/systemd/system/ursus.service << 'EOF'
[Unit]
Description=URSUS Stripe Connect Gateway
After=network.target

[Service]
Type=notify
User=ursus
Group=ursus
WorkingDirectory=/home/ursus/ursus
Environment="PATH=/home/ursus/ursus/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PYTHONPATH=/home/ursus/ursus"

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

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Systemd service recreated${NC}"

# ====================================================
# Step 7: Check .env file
# ====================================================
echo -e "${BLUE}7. Checking .env configuration...${NC}"

if [ ! -f "/home/ursus/ursus/.env" ]; then
    echo -e "${RED}✘ .env file not found!${NC}"
    echo -e "${YELLOW}Creating .env from example...${NC}"
    cp /home/ursus/ursus/.env.example /home/ursus/ursus/.env
    chown ursus:ursus /home/ursus/ursus/.env
    chmod 600 /home/ursus/ursus/.env
    echo -e "${YELLOW}⚠ You MUST edit /home/ursus/ursus/.env with your Stripe keys!${NC}"
else
    echo -e "${GREEN}✓ .env file exists${NC}"
    
    # Check if critical keys are set
    if grep -q "sk_live_your_platform_secret_key_here" /home/ursus/ursus/.env; then
        echo -e "${YELLOW}⚠ WARNING: Stripe keys not configured in .env!${NC}"
        echo -e "${YELLOW}   Edit /home/ursus/ursus/.env before starting${NC}"
    fi
fi

# ====================================================
# Step 8: Reload and restart service
# ====================================================
echo -e "${BLUE}8. Reloading systemd and starting service...${NC}"

systemctl daemon-reload
systemctl enable ursus

echo ""
echo -e "${YELLOW}Attempting to start URSUS...${NC}"
systemctl start ursus

sleep 2

# Check status
if systemctl is-active --quiet ursus; then
    echo -e "${GREEN}✓✓✓ URSUS is running successfully!${NC}"
    systemctl status ursus --no-pager
else
    echo -e "${RED}✘ Service still failing. Checking logs...${NC}"
    echo ""
    echo -e "${YELLOW}Last 30 lines of journal:${NC}"
    journalctl -u ursus -n 30 --no-pager
    echo ""
    echo -e "${YELLOW}Error log:${NC}"
    tail -20 /var/log/ursus/error.log 2>/dev/null || echo "No error log yet"
fi

echo ""
echo -e "${BLUE}=========================================="
echo "  Additional Diagnostic Commands"
echo "==========================================${NC}"
echo ""
echo "Check status:     systemctl status ursus"
echo "View live logs:   journalctl -u ursus -f"
echo "View error log:   tail -f /var/log/ursus/error.log"
echo "Check .env:       cat /home/ursus/ursus/.env"
echo "Test manually:    su - ursus -c 'cd /home/ursus/ursus && source venv/bin/activate && gunicorn --bind 127.0.0.1:4242 app:app'"
echo ""