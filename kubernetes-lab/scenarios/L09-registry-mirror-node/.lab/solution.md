# L09 - one node's registry config

**Root cause**: the "config refresh" on `k8s-w1` changed `/etc/containerd/certs.d/registry.lab:5000/hosts.toml`
to `http://registry.lab:5050` (nothing listens there). containerd uses that file for every pull from
`registry.lab:5000`. Its in-cluster mirror settings are per node, so only w1 failed, and only for images it
hadn't cached yet.

**Diagnosis**
```
kubectl -n edge get pods -o wide                           # the w1 pod: ImagePullBackOff
kubectl -n edge describe pod <w1 pod> | grep -A3 Failed    # dial tcp ...:5050: connection refused
./lab node w1
sudo crictl pull registry.lab:5000/lab/labapp:1.3          # same error, no Kubernetes involved
diff <(sudo cat /etc/containerd/certs.d/registry.lab:5000/hosts.toml) <(ssh w2 ...)   # or eyeball both
```

**Fix**: `http://registry.lab:5000` back in `hosts.toml`; containerd reads it per pull. Delete the pod (or wait
for the back-off) to retry.

**Interview notes**
- containerd 2.x registry config: `config_path = "/etc/containerd/certs.d"` + one `hosts.toml` per registry
  host (`server`, `[host."<mirror>"]` with `capabilities`, `skip_verify`, `ca`, `override_path`). The old
  `mirrors` block in `config.toml` is deprecated.
- "Works on some nodes" means look for per-node state: runtime config, cached images, `/etc/hosts`, CA files,
  the clock.
- `crictl pull` on the node removes Kubernetes from the picture. If it fails too, the problem is the runtime
  or the network, not the pod spec (imagePullSecrets, image name).
- Config drift is why the lab keeps a golden copy. In real fleets: config management or immutable node
  images, not hand edits.
