## Step 1: Run a Flask Application in Docker

First, let's build a simple Python/Flask application.

```bash
cat << 'EOF' > app.py
from flask import Flask, jsonify
from multiprocessing import Process, Value
import math, json, hashlib, random, os, time, signal

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
    # Run heavy_computation in a tight loop until stop_flag is set
    while True:
        if stop_flag.value == 1:
            break
        # perform CPU-bound work; avoid sleeps to maximize CPU usage
        heavy_computation_once()

# global tracker for worker processes and stop flag
_worker_processes = []
_stop_flag = None

@app.route("/")
def hello():
    return "Hello, CPU stress workers running."

@app.route("/compute")
def compute():
    h, f = heavy_computation_once()
    return f"Hash: {h[:10]}, Fib(10)={f}"

@app.route("/status")
def status():
    pids = [p.pid for p in _worker_processes if p.is_alive()]
    return jsonify({
        "worker_count": len(pids),
        "pids": pids
    })

def start_workers(num_workers):
    global _worker_processes, _stop_flag
    if _stop_flag is None:
        _stop_flag = Value('i', 0)
    # avoid starting duplicate workers
    if any(p.is_alive() for p in _worker_processes):
        return
    _worker_processes = []
    for i in range(num_workers):
        p = Process(target=worker_loop, args=(_stop_flag,))
        p.daemon = True
        p.start()
        _worker_processes.append(p)

def stop_workers():
    global _worker_processes, _stop_flag
    if _stop_flag is not None:
        _stop_flag.value = 1
    for p in _worker_processes:
        try:
            p.join(timeout=2)
        except Exception:
            pass
    _worker_processes = []

def _graceful_shutdown(signum, frame):
    stop_workers()
    # allow Flask to exit
    try:
        os._exit(0)
    except SystemExit:
        raise

if __name__ == "__main__":
    # number of worker processes (default: all logical CPUs)
    default_workers = os.cpu_count() or 1
    num_workers = int(os.environ.get("STRESS_WORKERS", default_workers))

    # optional: if you want NOT to auto-start, set env STRESS_AUTOSTART=0
    autostart = os.environ.get("STRESS_AUTOSTART", "1")
    if autostart == "1":
        start_workers(num_workers)

    # handle SIGTERM/SIGINT to stop workers cleanly
    signal.signal(signal.SIGTERM, _graceful_shutdown)
    signal.signal(signal.SIGINT, _graceful_shutdown)

    # Run Flask (use 0.0.0.0 for container)
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