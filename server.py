import os
import hmac
import hashlib
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)
TERRAFORM_DIR = "/app/terraform"


@app.route("/webhook", methods=["POST"])
def webhook():
    webhook_token = os.environ.get("WEBHOOK_TOKEN", "changeme")
    signature_received = request.headers.get("X-Gitea-Signature", "")
    body_bytes = request.get_data()

    signature_calculated = hmac.new(
        key=webhook_token.encode(), msg=body_bytes, digestmod=hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(signature_received, signature_calculated):
        return jsonify({"message": "Invalid key"}), 403

    try:
        result = subprocess.run(
            ["terraform", "apply", "-auto-approve"],
            cwd=TERRAFORM_DIR,
            capture_output=True,
            text=True,
        )
        return jsonify(
            {"status": "success", "stdout": result.stdout, "stderr": result.stderr}
        )
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route("/", methods=["GET"])
def health():
    return jsonify({"status": "running"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
