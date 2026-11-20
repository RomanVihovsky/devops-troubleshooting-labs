# R07 - the kubelet's podPidsLimit counts threads

**Root cause**: w1's kubelet has `podPidsLimit: 64`. The kubelet writes it into every pod's cgroup as `pids.max`,
and Linux counts **threads** as tasks in the pids controller. labapp starts 100 worker threads (plus Python's own),
so `pthread_create` fails with EAGAIN - *can't start new thread* (shells say *fork: retry: Resource temporarily
unavailable*). Only pods on w1 are affected; resources look fine because pids aren't a resource you see in `kubectl
top`.

**Diagnosis**
```
kubectl -n reports logs deploy/reports-api
./lab node w1
  grep -i pid /var/lib/kubelet/config.yaml
  cat /sys/fs/cgroup/kubepods.slice/kubepods-besteffort.slice/*/pids.max      # 64
  cat /sys/fs/cgroup/kubepods.slice/kubepods-besteffort.slice/*/pids.peak
```

**Fix**: remove `podPidsLimit` (or raise it - 4096 is a common default for hardened nodes), restart the kubelet,
and recreate the pods: the limit is applied when the pod's cgroup is created.

**Interview notes**
- Fork-bomb protection is legitimate - size it from real workloads (`pids.peak`), not a guess; JVMs and Go
  runtimes use many threads.
- Node-level: `--system-reserved`/`kubeReserved` pid reservations and `pid.available` eviction signals.
- The same EAGAIN comes from `ulimit -u` (RLIMIT_NPROC) in containers, or from `kernel.pid_max`/`threads-max`.
