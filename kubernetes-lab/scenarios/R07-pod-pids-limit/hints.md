## Hint 1
A thread is a task for the kernel's **pids** controller, just like a process. `./lab node w1`, then find the pod's
cgroup: `cat /sys/fs/cgroup/kubepods.slice/*/*/pids.max` (or `systemd-cgls`). What's the limit?

## Hint 2
The kubelet caps every pod with `podPidsLimit` from `/var/lib/kubelet/config.yaml` - `grep -i pid` there.

## Hint 3
Remove `podPidsLimit` (or raise it to e.g. 4096), `systemctl restart kubelet`, then delete the crashing pods: the
limit is written into a pod's cgroup when the pod is created.
