"""
====================================================
    URSUS - Stripe Connect Gateway Service
    Version: 2.0.0 - Production Ready
    
    Purpose: Automated revenue routing between Platform
             Account and Connected Account using Stripe
             Connect with Merchant of Record (MoR) model.
    
    Security Features:
    - API Key Authentication
    - Rate Limiting
    - Input Validation
    - Idempotency Protection
    - Webhook Signature Verification
====================================================
"""

import os
import logging
import hashlib
import time
from functools import wraps
from datetime import datetime
from decimal import Decimal
from typing import Tuple, Dict, Any

from dotenv import load_dotenv
from flask import Flask, request, jsonify, Response
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import stripe

# ====================================================
#  Environment & Configuration
# ====================================================
load_dotenv()

# Validate required environment variables
REQUIRED_ENV_VARS = [
    "STRIPE_SECRET_KEY",
    "STRIPE_WEBHOOK_SECRET",
    "CONNECTED_ACCOUNT_ID",
    "URSUS_API_KEY"
]

missing_vars = [var for var in REQUIRED_ENV_VARS if not os.getenv(var)]
if missing_vars:
    raise RuntimeError(f"Missing required environment variables: {', '.join(missing_vars)}")

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")
CONNECTED_ACCOUNT_ID = os.getenv("CONNECTED_ACCOUNT_ID")
URSUS_API_KEY = os.getenv("URSUS_API_KEY")
FLASK_ENV = os.getenv("FLASK_ENV", "production")
PLATFORM_NAME = os.getenv("PLATFORM_NAME", "Platform Account")
CONNECTED_NAME = os.getenv("CONNECTED_NAME", "Connected Account")

# ====================================================
#  Logging Configuration
# ====================================================
logging.basicConfig(
    level=logging.INFO if FLASK_ENV == "production" else logging.DEBUG,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# ====================================================
#  Flask App Initialization
# ====================================================
app = Flask(__name__)

# Disable debug mode in production
if FLASK_ENV == "production":
    app.config['DEBUG'] = False
    app.config['TESTING'] = False

# ====================================================
#  Rate Limiting
# ====================================================
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per hour"],
    storage_uri="memory://"
)

# ====================================================
#  Fee Configuration
# ====================================================
# Stripe fees: 2.9% + $0.30 per transaction
STRIPE_FEE_PERCENT = Decimal("0.029")  # 2.9%
STRIPE_FEE_FIXED = 30  # $0.30 in cents

# Platform commission: 1% of (amount - stripe fees)
PLATFORM_COMMISSION_PERCENT = Decimal("0.01")  # 1%

# Payment limits (in cents)
MIN_PAYMENT_AMOUNT = 50  # $0.50 (Stripe minimum)
MAX_PAYMENT_AMOUNT = 99999999  # $999,999.99

# ====================================================
#  In-Memory Store for Idempotency
# ====================================================
# Production: Replace with Redis
processed_charges = set()

# ====================================================
#  Authentication Decorator
# ====================================================
def require_api_key(f):
    """Validates API key from X-API-Key header"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        provided_key = request.headers.get('X-API-Key')
        
        if not provided_key:
            logger.warning(f"API request without key from {request.remote_addr}")
            return jsonify({"error": "Missing API key"}), 401
        
        if provided_key != URSUS_API_KEY:
            logger.warning(f"Invalid API key attempt from {request.remote_addr}")
            return jsonify({"error": "Invalid API key"}), 401
        
        return f(*args, **kwargs)
    return decorated_function

# ====================================================
#  Fee Calculation Functions
# ====================================================
def calculate_fees(amount_cents: int) -> Dict[str, int]:
    """
    Calculate fee breakdown for a payment.
    
    Flow:
    1. Deduct Stripe fees from gross amount
    2. Calculate platform commission (1% of net)
    3. Remainder goes to connected account
    
    Args:
        amount_cents: Total payment amount in cents
    
    Returns:
        Dictionary with stripe_fee, platform_commission, transfer_amount
    """
    amount = Decimal(amount_cents)
    
    # Calculate Stripe fees
    stripe_fee_variable = int(amount * STRIPE_FEE_PERCENT)
    stripe_fee_total = stripe_fee_variable + STRIPE_FEE_FIXED
    
    # Net amount after Stripe fees
    net_after_stripe = amount_cents - stripe_fee_total
    
    # Calculate platform commission (1% of net)
    platform_commission = int(Decimal(net_after_stripe) * PLATFORM_COMMISSION_PERCENT)
    
    # Amount to transfer to connected account
    transfer_amount = net_after_stripe - platform_commission
    
    # Validation: ensure math adds up
    assert amount_cents == stripe_fee_total + platform_commission + transfer_amount, \
        "Fee calculation error: amounts don't add up"
    
    return {
        "stripe_fee": stripe_fee_total,
        "platform_commission": platform_commission,
        "transfer_amount": transfer_amount,
        "net_after_stripe": net_after_stripe
    }

# ====================================================
#  Input Validation
# ====================================================
def validate_payment_amount(amount: Any) -> Tuple[bool, str, int]:
    """
    Validate payment amount.
    
    Returns:
        (is_valid, error_message, amount_cents)
    """
    if amount is None:
        return False, "Missing 'amount' field", 0
    
    try:
        amount_cents = int(amount)
    except (ValueError, TypeError):
        return False, "Invalid amount format (must be integer cents)", 0
    
    if amount_cents < MIN_PAYMENT_AMOUNT:
        return False, f"Amount too small (minimum ${MIN_PAYMENT_AMOUNT/100:.2f})", 0
    
    if amount_cents > MAX_PAYMENT_AMOUNT:
        return False, f"Amount too large (maximum ${MAX_PAYMENT_AMOUNT/100:.2f})", 0
    
    return True, "", amount_cents

# ====================================================
#  Create PaymentIntent Endpoint
# ====================================================
@app.route("/create-payment-intent", methods=["POST"])
@require_api_key
@limiter.limit("10 per minute")
def create_payment_intent() -> Tuple[Response, int]:
    """
    Creates a PaymentIntent on behalf of Platform Account.
    
    Required Headers:
        X-API-Key: Your URSUS API key
    
    Required JSON Body:
        amount: Payment amount in cents (integer)
        order_id: (optional) Your order identifier
        customer_email: (optional) Customer email for receipt
    """
    try:
        data = request.get_json(force=True)
    except Exception as e:
        logger.error(f"Invalid JSON payload: {e}")
        return jsonify({"error": "Invalid JSON"}), 400
    
    # Validate amount
    is_valid, error_msg, amount = validate_payment_amount(data.get("amount"))
    if not is_valid:
        logger.warning(f"Invalid payment amount from {request.remote_addr}: {error_msg}")
        return jsonify({"error": error_msg}), 400
    
    # Calculate fees for metadata
    fees = calculate_fees(amount)
    
    # Generate order ID if not provided
    order_id = data.get("order_id")
    if not order_id:
        order_id = f"ORD-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
    
    # Sanitize order_id (max 500 chars, alphanumeric + dashes)
    order_id = ''.join(c for c in order_id if c.isalnum() or c in ['-', '_'])[:500]
    
    customer_email = data.get("customer_email", "").strip()
    if customer_email and len(customer_email) > 200:
        customer_email = customer_email[:200]
    
    try:
        intent = stripe.PaymentIntent.create(
            amount=amount,
            currency="usd",
            automatic_payment_methods={
                "enabled": True,
                "allow_redirects": "never"
            },
            metadata={
                "order_id": order_id,
                "source": "Ursus",
                "stripe_fee": fees["stripe_fee"],
                "platform_commission": fees["platform_commission"],
                "transfer_amount": fees["transfer_amount"]
            },
            receipt_email=customer_email if customer_email else None,
            statement_descriptor_suffix="URSUS",
            idempotency_key=hashlib.sha256(f"{order_id}-{amount}".encode()).hexdigest()[:24]
        )
        
        logger.info(f"PaymentIntent created: {intent.id} for ${amount/100:.2f} (order: {order_id})")
        
        return jsonify({
            "client_secret": intent.client_secret,
            "payment_intent_id": intent.id,
            "amount": amount,
            "fee_breakdown": {
                "stripe_fee": fees["stripe_fee"],
                "platform_commission": fees["platform_commission"],
                "transfer_to_connected": fees["transfer_amount"]
            }
        }), 200
        
    except stripe.error.CardError as e:
        logger.warning(f"Card error: {e.user_message}")
        return jsonify({"error": "Card declined"}), 400
    
    except stripe.error.RateLimitError:
        logger.error("Stripe rate limit hit")
        return jsonify({"error": "Service temporarily unavailable"}), 503
    
    except stripe.error.InvalidRequestError as e:
        logger.error(f"Invalid Stripe request: {e}")
        return jsonify({"error": "Invalid payment request"}), 400
    
    except stripe.error.AuthenticationError:
        logger.critical("Stripe authentication failed - check API keys")
        return jsonify({"error": "Payment service misconfigured"}), 500
    
    except stripe.error.StripeError as e:
        logger.error(f"Stripe error: {e}")
        return jsonify({"error": "Payment processing failed"}), 500
    
    except Exception as e:
        logger.exception(f"Unexpected error in create_payment_intent: {e}")
        return jsonify({"error": "Internal server error"}), 500

# ====================================================
#  Stripe Webhook Endpoint
# ====================================================
@app.route("/webhook", methods=["POST"])
@limiter.limit("1000 per hour")
def webhook_received() -> Tuple[str, int]:
    """
    Handles Stripe webhook events.
    Processes charge.succeeded and charge.refunded events.
    """
    payload = request.data
    sig_header = request.headers.get("Stripe-Signature")
    
    if not sig_header:
        logger.warning(f"Webhook without signature from {request.remote_addr}")
        return "Missing signature", 400
    
    # Verify webhook signature
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, WEBHOOK_SECRET
        )
    except stripe.error.SignatureVerificationError as e:
        logger.error(f"Invalid webhook signature: {e}")
        return "Invalid signature", 400
    except ValueError as e:
        logger.error(f"Invalid webhook payload: {e}")
        return "Invalid payload", 400
    except Exception as e:
        logger.exception(f"Webhook verification error: {e}")
        return "Webhook error", 400
    
    event_type = event.get("type")
    logger.info(f"Received webhook: {event_type} (ID: {event.get('id')})")
    
    # Process charge.succeeded events (only if captured)
    if event_type == "charge.succeeded":
        charge = event["data"]["object"]
        # Only process if charge is captured
        if charge.get("captured", False):
            handle_charge_succeeded(event)
        else:
            logger.info(f"Skipping uncaptured charge {charge['id']} - waiting for charge.captured event")
    
    # Process charge.captured events (for manually captured charges)
    elif event_type == "charge.captured":
        # Small delay to ensure Stripe has fully processed the capture
        logger.info("Waiting 2 seconds for Stripe to finalize capture...")
        time.sleep(2)
        handle_charge_succeeded(event)  # Process the transfer
    
    # Process charge.refunded events
    elif event_type == "charge.refunded":
        handle_charge_refunded(event)
    
    # Log other events for monitoring
    else:
        logger.debug(f"Unhandled event type: {event_type}")
    
    return "OK", 200

# ====================================================
#  Payment Intent Success Handler
# ====================================================
def handle_payment_intent_succeeded(event: Dict[str, Any]) -> None:
    """
    Process payment_intent.succeeded events (alternative to charge.succeeded).
    This fires when payment is captured via PaymentIntent API.
    """
    payment_intent = event["data"]["object"]
    
    # Get the charge ID from the payment intent
    charge_id = payment_intent.get("latest_charge")
    
    if not charge_id:
        logger.warning(f"PaymentIntent {payment_intent['id']} succeeded but no charge found")
        return
    
    # Retrieve the charge to get full details
    try:
        charge = stripe.Charge.retrieve(charge_id)
        
        # Only process if captured
        if not charge.get("captured", False):
            logger.info(f"Skipping uncaptured charge {charge_id} from PaymentIntent")
            return
        
        # Create a charge event structure for handle_charge_succeeded
        charge_event = {
            "data": {
                "object": charge
            }
        }
        
        # Small delay to ensure Stripe processes everything
        logger.info("Waiting 2 seconds for Stripe to finalize...")
        time.sleep(2)
        
        # Process the transfer
        handle_charge_succeeded(charge_event)
        
    except stripe.error.StripeError as e:
        logger.error(f"Failed to retrieve charge {charge_id}: {e}")
    except Exception as e:
        logger.exception(f"Unexpected error in handle_payment_intent_succeeded: {e}")

# ====================================================
#  Charge Success Handler
# ====================================================
def handle_charge_succeeded(event: Dict[str, Any]) -> None:
    """Process successful charge and transfer funds to Connected Account"""
    charge = event["data"]["object"]
    charge_id = charge["id"]
    amount = charge["amount"]
    
    # Idempotency check
    if charge_id in processed_charges:
        logger.info(f"Charge {charge_id} already processed, skipping")
        return
    
    # Calculate fees
    try:
        fees = calculate_fees(amount)
    except Exception as e:
        logger.error(f"Fee calculation failed for charge {charge_id}: {e}")
        return
    
    logger.info(
        f"Processing charge {charge_id}: "
        f"Amount=${amount/100:.2f}, "
        f"Stripe Fee=${fees['stripe_fee']/100:.2f}, "
        f"Platform Commission=${fees['platform_commission']/100:.2f}, "
        f"Transfer=${fees['transfer_amount']/100:.2f}"
    )
    
    # Create transfer to Connected Account
    try:
        transfer = stripe.Transfer.create(
            amount=fees["transfer_amount"],
            currency="usd",
            destination=CONNECTED_ACCOUNT_ID,
            source_transaction=charge_id,
            metadata={
                "initiated_by": "Ursus",
                "platform": PLATFORM_NAME,
                "connected": CONNECTED_NAME,
                "original_amount": amount,
                "stripe_fee": fees["stripe_fee"],
                "platform_commission": fees["platform_commission"]
            },
            idempotency_key=f"transfer_{charge_id}"
        )
        
        # Mark as processed
        processed_charges.add(charge_id)
        
        logger.info(
            f"✓ Transfer {transfer.id} completed: "
            f"${fees['transfer_amount']/100:.2f} → {CONNECTED_NAME}"
        )
        
    except stripe.error.InvalidRequestError as e:
        # Check if transfer already exists
        if "already been transferred" in str(e).lower():
            logger.warning(f"Transfer already exists for charge {charge_id}")
            processed_charges.add(charge_id)
        else:
            logger.error(f"Invalid transfer request for {charge_id}: {e}")
    
    except stripe.error.StripeError as e:
        logger.error(f"Stripe error during transfer for {charge_id}: {e}")
    
    except Exception as e:
        logger.exception(f"Unexpected error transferring funds for {charge_id}: {e}")

# ====================================================
#  Charge Refund Handler
# ====================================================
def handle_charge_refunded(event: Dict[str, Any]) -> None:
    """
    Log refunded charges for accounting purposes.
    
    IMPORTANT: Platform Account (MoR) bears all refund responsibility.
    Connected Account does NOT have transfers reversed - funds stay with them.
    Platform absorbs the refund cost from their own balance.
    """
    charge = event["data"]["object"]
    charge_id = charge["id"]
    refund_amount = charge.get("amount_refunded", 0)
    
    if refund_amount == 0:
        logger.warning(f"Refund event for {charge_id} but amount_refunded is 0")
        return
    
    # Calculate what the original transfer was
    try:
        original_fees = calculate_fees(charge["amount"])
    except:
        original_fees = {"transfer_amount": 0}
    
    logger.info(
        f"📋 Refund processed for charge {charge_id}: ${refund_amount/100:.2f} "
        f"(Original transfer to {CONNECTED_NAME}: ${original_fees['transfer_amount']/100:.2f}) - "
        f"{PLATFORM_NAME} absorbs refund cost as MoR"
    )
    
    # For accounting/audit purposes, log the refund
    # But DO NOT reverse the transfer - Connected Account keeps their funds
    logger.info(
        f"💰 {CONNECTED_NAME} funds retained. "
        f"{PLATFORM_NAME} balance impact: -${refund_amount/100:.2f}"
    )

# ====================================================
#  Health Check Endpoint
# ====================================================
@app.route("/health", methods=["GET"])
def health_check() -> Tuple[Response, int]:
    """Health check endpoint for monitoring"""
    try:
        # Verify Stripe connectivity
        stripe.Account.retrieve(CONNECTED_ACCOUNT_ID)
        
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "environment": FLASK_ENV,
            "stripe_connected": True
        }), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            "status": "unhealthy",
            "error": "Stripe connectivity issue"
        }), 503

# ====================================================
#  Root Endpoint
# ====================================================
@app.route("/", methods=["GET"])
def home() -> Tuple[Response, int]:
    """Return 404 for security - hide service info"""
    return jsonify({"error": "Not found"}), 404

# ====================================================
#  Error Handlers
# ====================================================
@app.errorhandler(404)
def not_found(e) -> Tuple[Response, int]:
    return jsonify({"error": "Endpoint not found"}), 404

@app.errorhandler(405)
def method_not_allowed(e) -> Tuple[Response, int]:
    return jsonify({"error": "Method not allowed"}), 405

@app.errorhandler(429)
def rate_limit_exceeded(e) -> Tuple[Response, int]:
    return jsonify({"error": "Rate limit exceeded"}), 429

@app.errorhandler(500)
def internal_error(e) -> Tuple[Response, int]:
    logger.exception("Internal server error")
    return jsonify({"error": "Internal server error"}), 500

# ====================================================
#  Run Server
# ====================================================
if __name__ == "__main__":
    logger.info("=" * 50)
    logger.info("  URSUS - Stripe Connect Gateway v2.0")
    logger.info("  Environment: " + FLASK_ENV)
    logger.info("=" * 50)
    
    if FLASK_ENV == "production":
        logger.warning("Running in production mode - use Gunicorn for deployment")
    
    port = int(os.getenv("PORT", 4242))
    app.run(
        host="0.0.0.0",
        port=port,
        debug=(FLASK_ENV != "production")
    )