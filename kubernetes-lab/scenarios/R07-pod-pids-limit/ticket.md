# reports-api crashes on k8s-w1 with "can't start new thread"
**INC-2750** · P2 · Reporter: team reports

`reports-api` must run on `k8s-w1` (it reads the node-local report cache) and starts 100 worker threads - it
always has. Since the node "hardening" last night its pods die right at start-up: *FATAL: cannot start 100
worker threads: can't start new thread*. The same image runs fine on the other workers, memory and CPU are
plentiful, and the code didn't change. The 100 threads are needed.

**Test**: `reports-api` runs 2 Ready pods on `k8s-w1` with `WORKER_THREADS=100`, stable for 60 s; w1's kubelet
allows a sane number of processes per pod (no `podPidsLimit`, or at least 1024).
