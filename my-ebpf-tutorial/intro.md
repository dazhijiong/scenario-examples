# Introduction

This small project shows how to run a Python/Flask app inside a Docker container and profile it with Linux perf and FlameGraph.

The app keeps the CPU busy (Fibonacci, math operations, hashing, JSON), which makes it easier to capture useful samples.

With this exercise you will learn how to:
- Find the process PID that actually consumes CPU inside a container
- Use perf to collect stack samples
- Generate a FlameGraph to visualize where time is spent

In the end you will have a `flamegraph.svg` file that you can open in a browser to explore interactively.

This is for educational purposes and only uses standard Linux profiling tools.
