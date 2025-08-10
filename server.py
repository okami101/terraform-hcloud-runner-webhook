from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)
TERRAFORM_DIR = "/app/terraform"


@app.route("/webhook", methods=["POST"])
def webhook():
    secret = request.headers.get("X-Webhook-Token")
    if secret != os.environ.get("WEBHOOK_TOKEN", "changeme"):
        return jsonify({"status": "forbidden"}), 403

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
