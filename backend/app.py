
import os
import tempfile
from flask import Flask, request, jsonify
from flask_cors import CORS
from inference_sdk import InferenceHTTPClient, InferenceConfiguration

app = Flask(__name__)
CORS(app)

API_KEY = os.environ.get("ROBOFLOW_API_KEY")

if not API_KEY:
    raise RuntimeError("ROBOFLOW_API_KEY is missing.")

client = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key=API_KEY
).configure(
    InferenceConfiguration(api_key_transport="header")
)

WORKSPACE = "vaibhavsnair2013-gmail-com"
WORKFLOW = "ai-pest-detector-k8rna-3-yolo26n-t2-vai-pest-detector-k8rna-3-yolo26n-t2-logic"

@app.get("/")
def home():
    return jsonify({"status": "online", "service": "PestGuard"})

@app.post("/detect")
def detect():
    if "image" not in request.files:
        return jsonify({"success": False, "error": "No image uploaded"}), 400

    uploaded = request.files["image"]

    if not uploaded.filename:
        return jsonify({"success": False, "error": "No image selected"}), 400

    temp_path = None

    try:
        suffix = os.path.splitext(uploaded.filename)[1] or ".jpg"

        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp:
            uploaded.save(temp)
            temp_path = temp.name

        result = client.run_workflow(
            workspace_name=WORKSPACE,
            workflow_id=WORKFLOW,
            images={"image": temp_path}
        )

        return jsonify({"success": True, "result": result})

    except Exception:
        app.logger.exception("Roboflow detection failed")
        return jsonify({
            "success": False,
            "error": "Roboflow detection failed. Check the backend terminal."
        }), 502

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
