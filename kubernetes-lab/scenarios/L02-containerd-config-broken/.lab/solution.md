# L02 - containerd won't start: a TOML syntax error

**Root cause**: the appended table header `[plugins.'io.containerd.cri.v1.images'` lacks its `]`. containerd
fails to parse its config and exits; the kubelet can't reach the CRI socket: `container runtime is down`,
node NotReady. Running containers keep running (their shims are independent) - new pods can't start.

**Diagnosis**: `kubectl describe node k8s-w1`; on the node `systemctl status containerd`, `journalctl -u
containerd`, `containerd config dump` (prints the parse error with line/column).

**Fix**: closing the bracket alone gives a second error - the table `[plugins.'io.containerd.cri.v1.images']`
already exists, and TOML doesn't allow it twice. Move `max_concurrent_downloads = 10` into the existing
table, validate with `containerd config dump`, restart containerd.

**Interview notes**
- Validate before restarting: `containerd config dump`, `kubelet --config ... --dry-run` doesn't exist -
  but `systemd-analyze verify`, `nginx -t`, `haproxy -c` do. Change one node first.
- containerd 2.x uses config version 3 with renamed plugin sections (`io.containerd.cri.v1.images`,
  `...runtime`); copying 1.x snippets (`io.containerd.grpc.v1.cri`) silently does nothing.
- `crictl` talks to the same socket: `crictl info` is the quickest runtime health check on a node.
