## Step 1: Run a Flask Application in Docker

First, let's build a simple Python/Flask application.

```bash
cat << 'EOF' > app.py
from flask import Flask, jsonify          # Flask provides a simple web server; jsonify returns JSON responses
import math, json, hashlib, random, os, threading, signal  # Import math, JSON, hashing, randomness, threading, and signals

app = Flask(__name__)                      # Create a Flask application instance

def fibonacci(n):
    # Recursive Fibonacci function to generate CPU load
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

def heavy_computation_once():
    # Perform a single round of heavy computation to create varied call stacks
    data = [random.random() for _ in range(1000)]  # Generate 1000 random numbers
    results = [math.sin(x) * math.cos(x) / (x + 0.001) for x in data]  # Do math operations
    text = "".join(str(r) for r in results[:100])  # Convert part of the results to string
    digest = hashlib.sha256(text.encode()).hexdigest()  # Compute a SHA256 hash
    parsed = json.loads(json.dumps({"hash": digest, "values": results[:10]}))  # Serialize/deserialize JSON
    fib_val = fibonacci(10)  # Call Fibonacci for more CPU work
    return parsed["hash"], fib_val

def worker_loop(stop_flag):
    # Background loop to continuously run heavy computation until stop flag is set
    while not stop_flag["stop"]:
        heavy_computation_once()

# Global variables to manage the background worker thread
_worker_thread = None
_stop_flag = {"stop": False}

@app.route("/")
def hello():
    # Root endpoint to show the app is running
    return "Hello, this is the tutorial of hanzhizh in kth devops."

@app.route("/compute")
def compute():
    # Run one round of heavy computation and return partial results
    h, f = heavy_computation_once()
    return f"Hash: {h[:10]}, Fib(10)={f}, kth devops"

@app.route("/status")
def status():
    # Return current worker status and process PID — useful to know which PID to profile
    return jsonify({
        "worker_running": _worker_thread.is_alive() if _worker_thread else False,
        "pid": os.getpid()
    })

def start_worker():
    # Start the background worker thread
    global _worker_thread, _stop_flag
    if _worker_thread and _worker_thread.is_alive():
        return
    _stop_flag["stop"] = False
    _worker_thread = threading.Thread(target=worker_loop, args=(_stop_flag,))
    _worker_thread.daemon = True
    _worker_thread.start()

def stop_worker():
    # Stop the background worker thread safely
    global _worker_thread, _stop_flag
    _stop_flag["stop"] = True
    if _worker_thread:
        _worker_thread.join(timeout=2)
    _worker_thread = None

def _graceful_shutdown(signum, frame):
    # Handle termination signals and stop the worker before exiting
    stop_worker()
    try:
        os._exit(0)
    except SystemExit:
        raise

if __name__ == "__main__":
    # Main entry point — automatically start the CPU stress worker unless disabled
    autostart = os.environ.get("STRESS_AUTOSTART", "1")
    if autostart == "1":
        start_worker()

    # Register SIGTERM and SIGINT handlers for graceful container shutdown
    signal.signal(signal.SIGTERM, _graceful_shutdown)
    signal.signal(signal.SIGINT, _graceful_shutdown)

    # Start the Flask app on port 5000 and listen on all interfaces
    app.run(host="0.0.0.0", port=5000)
EOF

```

Now create a `Dockerfile`:

```bash
cat << 'EOF' > Dockerfile
FROM python:3.9-slim
WORKDIR /app                # Set the working directory inside the container to /app
COPY app.py /app/           # Copy the local app.py into the container’s /app directory
RUN pip install flask       # Install Flask inside the container
CMD ["python", "app.py"]    # Define the default command: Run Flask when the container starts
EOF

```

````markdown
Build and run the container:

```bash
docker build -t flask-app .
docker run -d --name flask-app -p 5000:5000 -e STRESS_WORKERS=1 flask-app
````

The `docker build -t flask-app .` command builds a Docker image from the current directory and tags it as `flask-app` so it can be referenced easily later. The `docker run -d --name flask-app -p 5000:5000 -e STRESS_WORKERS=1 flask-app` command starts a new container from that image in detached mode, names it `flask-app` for easier management, maps port 5000 of the container to port 5000 on the host so you can access the Flask app in a browser, and sets the `STRESS_WORKERS=1` environment variable to automatically start one CPU stress worker inside the container.


Test the application:

```bash
curl http://localhost:5000/
```