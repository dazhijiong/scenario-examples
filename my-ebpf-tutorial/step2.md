# Step 2: Profile the Application with perf and FlameGraph

In this step we will use **perf** and **FlameGraph** to analyze performance of our containerized Python/Flask app.

---

### 1. Keep the Application Busy

Keep the Flask container running from **Step 1**.

The app already starts a CPU-intensive worker in the background (computing Fibonacci, math ops, hashing).  
So you **don’t need an external load tool** like `wrk`. The worker itself will keep the CPU busy enough for profiling.

---

### 2. Profiling with perf (CPU FlameGraph)

Find the container’s active Python processes on the host:

```bash
docker top flask-app
```

You will see output like:

```
UID   PID   PPID  C   STIME   TTY  TIME     CMD
root  5933  5912  0   ...     ?    00:00:00 python app.py
root  5955  5933  97  ...     ?    00:02:11 python app.py
```

- **PID 5933** → parent Flask server (low CPU).  
- **PID 5955** → worker loop consuming ~97% CPU.  

👉 Always choose the **PID with highest CPU usage** (here `5955`) for profiling.

Run `perf` against that PID:

```bash
sudo perf record -F 99 -p 5955 -g --call-graph dwarf -- sleep 30
sudo perf script > out.perf
```

Install FlameGraph tools (if not done already):

```bash
git clone https://github.com/brendangregg/Flamegraph.git
```

Generate the folded stacks and FlameGraph:

```bash
./Flamegraph/stackcollapse-perf.pl out.perf > out.folded
./Flamegraph/flamegraph.pl out.folded > flamegraph.svg
```

Now download `flamegraph.svg` and open it in your browser. The file is interactive:  

- **Y-axis = Call stack depth**  
  Each row is one stack frame (a function). The **top block** is the function currently executing, and the blocks below are its parents (callers). The deeper the stack, the taller the flame.  

- **X-axis = Aggregated samples**  
  The width of a block shows how often that function appeared in collected samples. A wider block means the function consumed more cumulative CPU time.  
  ⚠️ Important: the X-axis is **not a time axis**. Functions are laid out alphabetically after merging stacks, so horizontal position has no chronological meaning.  

- **Colors**  
  By default, colors are only for visual distinction between functions. They do not represent heat, duration, or resource type (unless using a customized palette).  

- **How to read it**  
  - **Wide blocks** → functions where most CPU time is spent.  
  - **Tall spikes** → deep call stacks, often from recursion or nested calls.  
  - To investigate a hotspot, start at the wide block on top and trace downward to see which functions led there.  


---

### 3. Interpreting the FlameGraph

Typical observations:

- **Wide blocks** = loops or frequently executed functions.  
- **Tall spikes** = recursive functions (e.g. our `fibonacci(n)`), because each call adds another stack frame.  
- **`_PyEval_EvalFrameDefault`** = Python interpreter main loop (expected in Python workloads).  
- **`_PyLong_New`, `PyNumber_InPlaceAdd`** = Python integer object creation and arithmetic.  
- **`[libpython3.9.so.1.0]`** = calls into Python C API.  
---

✅ At this point, you should have produced a `flamegraph.svg` file that visually demonstrates where your Python/Flask app spends CPU time under load.
