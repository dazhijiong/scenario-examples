# Introduction

This small project shows how to run a Python/Flask app inside a Docker container and profile it with Linux **perf** and **FlameGraph**.  
Behind the scenes, `perf` leverages Linux **eBPF** (extended Berkeley Packet Filter) to efficiently collect low-level performance data such as stack traces from running processes, with very low overhead.

---

## Why not just use CLI tools?

Traditional CLI tools like `top` or `strace` can show CPU usage or system calls but are limited to:
- **Snapshots only** — no full picture of where time is spent  
- **Hard-to-read output** — long lists of functions without structure  
- **Little interactivity** — hard to drill down for root cause  

**FlameGraphs** solve this by:
- **Interactive visualization** — zoom & search for hotspots
- **Aggregated call stacks** — clear view of where CPU time goes
- **Quick insight** — easier to spot bottlenecks

---

## Why this matters for DevOps

This approach provides DevOps teams with a fast and intuitive way to understand application performance inside containerized environments. By using **perf** and **FlameGraph** early in the development and CI/CD process, teams can detect potential performance bottlenecks and regressions sooner, reduce debugging time, and accelerate iteration cycles — all while maintaining system stability and delivery speed.

---

The app keeps the CPU busy (Fibonacci, math operations, hashing, JSON), which makes it easier to capture useful samples.

With this exercise you will learn how to:
- Find the process PID that actually consumes CPU inside a container
- Use **perf** (powered by eBPF) to collect stack samples
- Generate a **FlameGraph** to visualize where time is spent

In the end you will have a `flamegraph.svg` file that you can open in a browser to explore interactively.

> This is for educational purposes and only uses standard Linux profiling tools.
