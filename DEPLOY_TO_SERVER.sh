#!/bin/bash

# ====================================================
# URSUS Complete Deployment Script
# Push to GitHub + Deploy to Server
# ====================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "  URSUS Complete Deployment System"
echo "==========================================${NC}"
echo ""

# ====================================================
# PART 1: GIT SETUP & PUSH
# ====================================================

echo -e "${BLUE}📤 PART 1: GitHub Setup${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}✘ Git is not installed${NC}"
    echo "Install with: brew install git (macOS) or apt install git (Linux)"
    exit 1
fi

# Get GitHub info
read -p "Enter your GitHub username: " GITHUB_USER
read -p "Enter your repository name (e.g., stripe-connect): " REPO_NAME
read -p "Enter your GitHub email: " GITHUB_EMAIL

# Configure git
echo -e "${YELLOW}Configuring git...${NC}"
git config --global user.name "$GITHUB_USER"
git config --global user.email "$GITHUB_EMAIL"

# Initialize git if needed
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    git branch -M main
fi

# Add remote
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
if git remote | grep -q origin; then
    echo -e "${YELLOW}Updating remote URL...${NC}"
    git remote set-url origin "$REPO_URL"
else
    echo -e "${YELLOW}Adding remote...${NC}"
    git remote add origin "$REPO_URL"
fi

# Create .gitignore
echo -e "${YELLOW}Creating .gitignore...${NC}"
cat > .gitignore << 'EOF'
# Environment (NEVER COMMIT!)
.env
.env.local
.env.*.local

# Python
__pycache__/
*.py[cod]
*$py.class
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp

# Logs
*.log
logs/

# OS
.DS_Store
EOF

# Add all files
echo -e "${YELLOW}Adding files to git...${NC}"
git add .

# Commit
echo -e "${YELLOW}Creating commit...${NC}"
git commit -m "Initial URSUS v2.0 - Stripe Connect Gateway with Configuration System" || true

# Push
echo -e "${YELLOW}Pushing to GitHub (may prompt for token)...${NC}"
git push -u origin main

echo -e "${GREEN}✓ GitHub push complete!${NC}"
echo -e "${YELLOW}Repository: ${REPO_URL}${NC}"
echo ""

# ====================================================
# PART 2: SERVER DEPLOYMENT
# ====================================================

echo -e "${BLUE}🚀 PART 2: Server Deployment${NC}"
echo ""

read -p "Enter your server IP address: " SERVER_IP
read -p "Enter your server username (usually 'root'): " SERVER_USER
read -p "Enter your domain name (e.g., pay.yourdomain.com): " DOMAIN
read -p "Enter email for SSL certificate: " CERT_EMAIL

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Server: ${SERVER_IP}"
echo "  User: ${SERVER_USER}"
echo "  Domain: ${DOMAIN}"
echo "  Email: ${CERT_EMAIL}"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

echo -e "${BLUE}Connecting to server...${NC}"

# Create deployment command
DEPLOY_CMD=$(cat << 'ENDCMD'
#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  URSUS Server Deployment"
echo "==========================================${NC}"

REPO_URL=$1
DOMAIN=$2
EMAIL=$3

# Clone repository
echo -e "${BLUE}📁 Cloning repository...${NC}"
if [ -d "/home/ursus/ursus" ]; then
    echo -e "${YELLOW}Updating existing repository...${NC}"
    cd /home/ursus/ursus
    git pull origin main
else
    echo -e "${YELLOW}Cloning new repository...${NC}"
    git clone "$REPO_URL" /home/ursus/ursus
    cd /home/ursus/ursus
fi

echo -e "${GREEN}✓ Repository ready${NC}"

# Run deployment script
echo -e "${BLUE}🚀 Running deployment script...${NC}"
chmod +x deploy.sh
bash deploy.sh << DEPLOYEOF
$DOMAIN
$EMAIL
y
DEPLOYEOF

echo -e "${GREEN}=========================================="
echo "  Deployment Complete!"
echo "==========================================${NC}"

echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo ""
echo "1. Configure Stripe keys:"
echo "   cd /home/ursus/ursus"
echo "   source venv/bin/activate"
echo "   python3 config_app.py"
echo ""
echo "2. Then visit: http://$DOMAIN:5000 to enter your keys"
echo ""
echo "3. Restart service:"
echo "   systemctl restart ursus"
echo ""
echo "4. Test health endpoint:"
echo "   curl https://$DOMAIN/health"
echo ""
echo -e "${GREEN}🎉 Your URSUS gateway is ready!${NC}"
ENDCMD
)

# Execute deployment on server
echo "$DEPLOY_CMD" | ssh -t "${SERVER_USER}@${SERVER_IP}" \
    "bash -s $REPO_URL $DOMAIN $CERT_EMAIL"

echo -e "${GREEN}✓ Server deployment complete!${NC}"

# ====================================================
# PART 3: POST-DEPLOYMENT INFO
# ====================================================

echo ""
echo -e "${BLUE}=========================================="
echo "  Deployment Summary"
echo "==========================================${NC}"
echo ""

echo -e "${GREEN}✓ GitHub Repository:${NC}"
echo "  https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo ""

echo -e "${GREEN}✓ Server Information:${NC}"
echo "  IP: ${SERVER_IP}"
echo "  Domain: ${DOMAIN}"
echo ""

echo -e "${YELLOW}📝 Important URLs:${NC}"
echo "  Configuration App: http://${SERVER_IP}:5000"
echo "  API Endpoint: https://${DOMAIN}/create-payment-intent"
echo "  Webhook: https://${DOMAIN}/webhook"
echo "  Health Check: https://${DOMAIN}/health"
echo ""

echo -e "${YELLOW}🔧 Quick Commands:${NC}"
echo "  SSH: ssh ${SERVER_USER}@${SERVER_IP}"
echo "  Check Status: systemctl status ursus"
echo "  View Logs: journalctl -u ursus -f"
echo "  Restart: systemctl restart ursus"
echo ""

echo -e "${YELLOW}⚙️ Next Steps:${NC}"
echo ""
echo "1. SSH to your server:"
echo "   ssh ${SERVER_USER}@${SERVER_IP}"
echo ""
echo "2. Configure Stripe keys:"
echo "   cd /home/ursus/ursus && source venv/bin/activate"
echo "   python3 config_app.py"
echo ""
echo "3. Visit http://${SERVER_IP}:5000 and enter your 3 Stripe keys"
echo ""
echo "4. Restart the service:"
echo "   systemctl restart ursus"
echo ""
echo "5. Test the health endpoint:"
echo "   curl https://${DOMAIN}/health"
echo ""
echo "6. Configure webhook in Stripe Dashboard:"
echo "   URL: https://${DOMAIN}/webhook"
echo "   Events: charge.succeeded, charge.captured, charge.refunded"
echo ""

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}📞 Support:${NC}"
echo "  Email: contact@deskcodes.com"
echo "  Phone: +1 206-408-6213"
echo "  Hours: Mon-Fri 9AM-6PM EST"
echo ""

