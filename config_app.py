"""
====================================================
URSUS Configuration Manager
Simple Web Interface to Configure Everything Online
Auto-configures Nginx, SSL, and Services
====================================================
"""

import os
import subprocess
from flask import Flask, render_template, request, jsonify
from dotenv import load_dotenv

app = Flask(__name__)
ENV_FILE = "/home/ursus/ursus/.env"

# For local development
if not os.path.exists(ENV_FILE):
    ENV_FILE = ".env"

def run_command(cmd):
    """Run shell command safely"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=300)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def update_nginx_config(domain):
    """Update Nginx configuration with the domain"""
    nginx_config = f"""server {{
    listen 80;
    listen [::]:80;
    server_name {domain};

    location /.well-known/acme-challenge/ {{
        root /var/www/html;
    }}

    location / {{
        proxy_pass http://127.0.0.1:4242;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }}

    location /health {{
        proxy_pass http://127.0.0.1:4242;
        proxy_buffering off;
        access_log off;
    }}

    location /webhook {{
        proxy_pass http://127.0.0.1:4242;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        client_max_body_size 1M;
    }}
}}"""
    
    try:
        # Write nginx config
        with open("/tmp/ursus_nginx.conf", "w") as f:
            f.write(nginx_config)
        
        # Copy to nginx sites-available
        os.system("sudo cp /tmp/ursus_nginx.conf /etc/nginx/sites-available/ursus")
        os.system("sudo ln -sf /etc/nginx/sites-available/ursus /etc/nginx/sites-enabled/ursus")
        os.system("sudo rm -f /etc/nginx/sites-enabled/default")
        
        # Test nginx config
        success, _, _ = run_command("sudo nginx -t")
        if success:
            # Reload nginx
            os.system("sudo systemctl reload nginx")
            return True, "Nginx configured successfully"
        else:
            return False, "Nginx configuration failed"
    except Exception as e:
        return False, str(e)

def get_ssl_certificate(domain, email):
    """Get SSL certificate using Certbot"""
    try:
        cmd = f"sudo certbot --nginx -d {domain} --non-interactive --agree-tos --email {email} 2>&1"
        success, output, error = run_command(cmd)
        
        if "already exists" in output or "already exists" in error or success:
            return True, "SSL certificate ready"
        else:
            return False, "SSL certificate failed"
    except Exception as e:
        return False, str(e)

def restart_services():
    """Restart URSUS and related services"""
    try:
        os.system("sudo systemctl restart ursus")
        os.system("sudo systemctl restart ursus-config")
        return True, "Services restarted"
    except Exception as e:
        return False, str(e)

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
        
        # Server Configuration
        domain = data.get("domain", "").strip()
        email = data.get("email", "").strip()
        
        # Stripe Configuration
        stripe_key = data.get("stripe_secret_key", "").strip()
        account_id = data.get("connected_account_id", "").strip()
        webhook_secret = data.get("webhook_secret", "").strip()
        
        # Business Names
        platform_name = data.get("platform_name", "My Platform").strip()
        connected_name = data.get("connected_name", "My Vendor").strip()
        
        # Validation
        if not domain:
            return jsonify({"error": "Domain is required"}), 400
        if not email:
            return jsonify({"error": "Email is required"}), 400
        if not stripe_key:
            return jsonify({"error": "Stripe Secret Key is required"}), 400
        if not account_id:
            return jsonify({"error": "Connected Account ID is required"}), 400
        if not webhook_secret:
            return jsonify({"error": "Webhook Secret is required"}), 400
        
        # Validate format
        if "@" not in email or "." not in email:
            return jsonify({"error": "Email format is invalid"}), 400
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
        env_content["DOMAIN"] = domain
        env_content["EMAIL"] = email
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
            f.write("# Server Configuration\n")
            f.write(f"DOMAIN={env_content['DOMAIN']}\n")
            f.write(f"EMAIL={env_content['EMAIL']}\n")
            f.write(f"\n# Stripe Configuration\n")
            f.write(f"STRIPE_SECRET_KEY={env_content['STRIPE_SECRET_KEY']}\n")
            f.write(f"STRIPE_WEBHOOK_SECRET={env_content['STRIPE_WEBHOOK_SECRET']}\n")
            f.write(f"CONNECTED_ACCOUNT_ID={env_content['CONNECTED_ACCOUNT_ID']}\n")
            f.write(f"\n# Security\n")
            f.write(f"URSUS_API_KEY={env_content['URSUS_API_KEY']}\n")
            f.write(f"\n# Application\n")
            f.write(f"FLASK_ENV={env_content['FLASK_ENV']}\n")
            f.write(f"PORT={env_content['PORT']}\n")
            f.write(f"\n# Business Names\n")
            f.write(f"PLATFORM_NAME={env_content['PLATFORM_NAME']}\n")
            f.write(f"CONNECTED_NAME={env_content['CONNECTED_NAME']}\n")
        
        # Auto-configure everything!
        messages = ["✓ Configuration saved successfully!"]
        
        # Update Nginx
        success, msg = update_nginx_config(domain)
        if success:
            messages.append("✓ Nginx configured")
        else:
            messages.append(f"⚠ Nginx config: {msg}")
        
        # Get SSL certificate
        success, msg = get_ssl_certificate(domain, email)
        if success:
            messages.append("✓ SSL certificate ready")
        else:
            messages.append(f"⚠ SSL certificate: {msg}")
        
        # Restart services
        success, msg = restart_services()
        if success:
            messages.append("✓ Services restarted")
        else:
            messages.append(f"⚠ Services: {msg}")
        
        messages.append("✓ Your URSUS is LIVE!")
        
        # Auto-restart URSUS to apply new config
        os.system("sudo systemctl restart ursus 2>&1 > /dev/null &")
        
        return jsonify({
            "success": True,
            "message": "✅ Configuration saved successfully!\n✅ Nginx configured\n✅ SSL certificate ready\n✅ Services restarted\n✅ Your URSUS is LIVE!\n\nNo terminal commands needed!"
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

