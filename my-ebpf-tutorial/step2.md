## Step 2: Trace with eBPF and Generate FlameGraph

### 1. Use traditional tools
Check running processes:

```bash
top -b -n1 | head -20
```

Attach `strace` to the Flask process:

```bash
pid=$(pgrep -f "python app.py")
strace -p $pid
```

### 2. Trace with eBPF
List syscalls executed by the container:

```bash
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s\n", comm); }'
```

Monitor file I/O:

```bash
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'
```

Profile CPU usage:

```bash
pid=$(pgrep -f "python app.py")
perf record -F 99 -p $pid -g -- sleep 15
perf script > out.perf
```

### 3. Generate FlameGraph
```bash
cd Flamegraph
./stackcollapse-perf.pl ../out.perf > ../out.folded
./flamegraph.pl ../out.folded > ../flamegraph.svg
```

Now open `flamegraph.svg` to see which functions consume the most CPU.
