"""
====================================================
URSUS Configuration Manager
Simple Web Interface to Configure Stripe Keys
====================================================
"""

import os
from flask import Flask, render_template, request, jsonify
from dotenv import load_dotenv

app = Flask(__name__)
ENV_FILE = "/home/ursus/ursus/.env"

# For local development
if not os.path.exists(ENV_FILE):
    ENV_FILE = ".env"

@app.route("/", methods=["GET"])
def index():
    """Show configuration form"""
    # Load current values if they exist
    load_dotenv(ENV_FILE)
    current_config = {
        "stripe_secret_key": os.getenv("STRIPE_SECRET_KEY", ""),
        "connected_account_id": os.getenv("CONNECTED_ACCOUNT_ID", ""),
        "webhook_secret": os.getenv("STRIPE_WEBHOOK_SECRET", ""),
        "platform_name": os.getenv("PLATFORM_NAME", "My Platform"),
        "connected_name": os.getenv("CONNECTED_NAME", "My Vendor"),
    }
    return render_template("index.html", config=current_config)

@app.route("/save-config", methods=["POST"])
def save_config():
    """Save configuration to .env file"""
    try:
        data = request.get_json()
        
        stripe_key = data.get("stripe_secret_key", "").strip()
        account_id = data.get("connected_account_id", "").strip()
        webhook_secret = data.get("webhook_secret", "").strip()
        platform_name = data.get("platform_name", "My Platform").strip()
        connected_name = data.get("connected_name", "My Vendor").strip()
        
        # Validation
        if not stripe_key:
            return jsonify({"error": "Stripe Secret Key is required"}), 400
        if not account_id:
            return jsonify({"error": "Connected Account ID is required"}), 400
        if not webhook_secret:
            return jsonify({"error": "Webhook Secret is required"}), 400
        
        # Validate format
        if not stripe_key.startswith("sk_"):
            return jsonify({"error": "Stripe Secret Key must start with 'sk_'"}), 400
        if not account_id.startswith("acct_"):
            return jsonify({"error": "Connected Account ID must start with 'acct_'"}), 400
        if not webhook_secret.startswith("whsec_"):
            return jsonify({"error": "Webhook Secret must start with 'whsec_'"}), 400
        
        # Read existing .env
        env_content = {}
        if os.path.exists(ENV_FILE):
            with open(ENV_FILE, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        key, value = line.split("=", 1)
                        env_content[key.strip()] = value.strip()
        
        # Update values
        env_content["STRIPE_SECRET_KEY"] = stripe_key
        env_content["CONNECTED_ACCOUNT_ID"] = account_id
        env_content["STRIPE_WEBHOOK_SECRET"] = webhook_secret
        env_content["PLATFORM_NAME"] = platform_name
        env_content["CONNECTED_NAME"] = connected_name
        
        # Ensure required keys exist
        env_content.setdefault("FLASK_ENV", "production")
        env_content.setdefault("PORT", "4242")
        env_content.setdefault("URSUS_API_KEY", os.getenv("URSUS_API_KEY", "auto-generated"))
        
        # Write .env file
        with open(ENV_FILE, "w") as f:
            f.write("# Stripe Configuration\n")
            f.write(f"STRIPE_SECRET_KEY={env_content['STRIPE_SECRET_KEY']}\n")
            f.write(f"STRIPE_WEBHOOK_SECRET={env_content['STRIPE_WEBHOOK_SECRET']}\n")
            f.write(f"CONNECTED_ACCOUNT_ID={env_content['CONNECTED_ACCOUNT_ID']}\n")
            f.write(f"\n# Security\n")
            f.write(f"URSUS_API_KEY={env_content['URSUS_API_KEY']}\n")
            f.write(f"\n# Application\n")
            f.write(f"FLASK_ENV={env_content['FLASK_ENV']}\n")
            f.write(f"PORT={env_content['PORT']}\n")
            f.write(f"\n# Optional\n")
            f.write(f"PLATFORM_NAME={env_content['PLATFORM_NAME']}\n")
            f.write(f"CONNECTED_NAME={env_content['CONNECTED_NAME']}\n")
        
        return jsonify({
            "success": True,
            "message": "Configuration saved successfully! ✓"
        }), 200
        
    except Exception as e:
        return jsonify({"error": f"Error saving configuration: {str(e)}"}), 500

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint"""
    return jsonify({"status": "Config app is running"}), 200

if __name__ == "__main__":
    print("\n" + "="*50)
    print("  URSUS Configuration Manager")
    print("  Open: http://localhost:5000")
    print("="*50 + "\n")
    
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )

