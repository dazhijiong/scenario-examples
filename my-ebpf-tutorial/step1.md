## Step 1: Run a Flask Application in Docker

First, let's build a simple Python/Flask application.

```bash
cat << 'EOF' > app.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello, eBPF!"

@app.route("/compute")
def compute():
    s = 0
    for i in range(10**6):
        s += i
    return str(s)

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