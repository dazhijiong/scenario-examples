## Step 1: Run a Flask Application in Docker

First, let's build a simple Python/Flask application.

```bash
cat << 'EOF' > app.py
from flask import Flask, jsonify
import math, json, hashlib, random, os, threading, signal

app = Flask(__name__)

def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

def heavy_computation_once():
    # Mixed CPU-bound and C-call work to create varied stacks
    data = [random.random() for _ in range(1000)]
    results = [math.sin(x) * math.cos(x) / (x + 0.001) for x in data]
    text = "".join(str(r) for r in results[:100])
    digest = hashlib.sha256(text.encode()).hexdigest()
    parsed = json.loads(json.dumps({"hash": digest, "values": results[:10]}))
    fib_val = fibonacci(10)
    return parsed["hash"], fib_val

def worker_loop(stop_flag):
    while not stop_flag["stop"]:
        heavy_computation_once()

# global tracker for worker thread
_worker_thread = None
_stop_flag = {"stop": False}

@app.route("/")
def hello():
    return "Hello, CPU stress worker running in main process."

@app.route("/compute")
def compute():
    h, f = heavy_computation_once()
    print
    return f"Hash: {h[:10]}, Fib(10)={f}, kth devops"

@app.route("/status")
def status():
    return jsonify({
        "worker_running": _worker_thread.is_alive() if _worker_thread else False,
        "pid": os.getpid()
    })

def start_worker():
    global _worker_thread, _stop_flag
    if _worker_thread and _worker_thread.is_alive():
        return
    _stop_flag["stop"] = False
    _worker_thread = threading.Thread(target=worker_loop, args=(_stop_flag,))
    _worker_thread.daemon = True
    _worker_thread.start()

def stop_worker():
    global _worker_thread, _stop_flag
    _stop_flag["stop"] = True
    if _worker_thread:
        _worker_thread.join(timeout=2)
    _worker_thread = None

def _graceful_shutdown(signum, frame):
    stop_worker()
    try:
        os._exit(0)
    except SystemExit:
        raise

if __name__ == "__main__":
    autostart = os.environ.get("STRESS_AUTOSTART", "1")
    if autostart == "1":
        start_worker()

    signal.signal(signal.SIGTERM, _graceful_shutdown)
    signal.signal(signal.SIGINT, _graceful_shutdown)

    app.run(host="0.0.0.0", port=5000)



EOF
```

Now create a `Dockerfile`:

```bash
cat << 'EOF' > Dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY app.py /app/
RUN pip install flask
CMD ["python", "app.py"]
EOF
```

Build and run the container:

```bash
docker build -t flask-app .
docker run -d --name flask-app -p 5000:5000 -e STRESS_WORKERS=1 flask-app
```

Test the application:

```bash
curl http://localhost:5000/
```