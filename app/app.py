from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

# 1. Home Route (Shows metadata for verification)
@app.route('/')
def home():
    return jsonify({
        "status": "Healthy",
        "message": "Welcome to HASA Production App!",
        "version": "1.0.0",  # Change this to prove pipeline works!
        "hostname": socket.gethostname(),  # Proves load balancing
        "environment": os.getenv("APP_ENV", "production")
    })

# 2. Health Check Route (ALB pings this every 30 seconds)
@app.route('/health')
def health():
    return jsonify({"status": "UP"}), 200

# 3. Traffic Simulation Route (For logging)
@app.route('/simulate-traffic')
def simulate():
    app.logger.info("User requested traffic simulation")
    return jsonify({"action": "logged"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)