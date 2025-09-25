## Step 1: Run a Flask Application in Docker

First, let's build a simple Python/Flask application.

```bash
cat << 'EOF' > app.py
from flask import Flask
import math, json, hashlib, random

app = Flask(__name__)

# Recursive function to generate deep call stacks
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

# Mixed workload with math, string, hashing, JSON, and recursion
def heavy_computation():
    data = [random.random() for _ in range(1000)]
    # Floating-point math
    results = [math.sin(x) * math.cos(x) / (x+0.001) for x in data]
    # String operations
    text = "".join(str(r) for r in results[:100])
    # Hashing
    digest = hashlib.sha256(text.encode()).hexdigest()
    # JSON encode/decode
    parsed = json.loads(json.dumps({"hash": digest, "values": results[:10]}))
    # Recursion
    fib_val = fibonacci(10)
    return parsed["hash"], fib_val

@app.route("/")
def hello():
    return "Hello, eBPF!"

@app.route("/compute")
def compute():
    h, f = heavy_computation()
    return f"Hash: {h[:10]}, Fib(10)={f}"

if __name__ == "__main__":
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
docker run -d -p 5000:5000 --name flask-app flask-app
```

Test the application:

```bash
curl http://localhost:5000/
```