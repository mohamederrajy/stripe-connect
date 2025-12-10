#!/bin/bash

# ====================================================
# URSUS Configuration Manager Launcher
# ====================================================

echo ""
echo "=========================================="
echo "  URSUS Configuration Manager"
echo "=========================================="
echo ""

# Check if running in /home/ursus/ursus (production)
if [ "$PWD" = "/home/ursus/ursus" ]; then
    echo "✓ Running in production mode"
    source venv/bin/activate
    python3 config_app.py
else
    echo "✓ Running in development mode"
    echo "Make sure you have Flask installed:"
    echo "  pip install flask python-dotenv"
    echo ""
    python3 config_app.py
fi

