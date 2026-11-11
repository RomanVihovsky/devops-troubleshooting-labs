# K09 - an audit log path that only exists on the host

**Root cause**: `--audit-log-path=/var/log/kubernetes/audit/audit.log` is a path **inside the kube-apiserver
container**. The manifest mounted the policy directory but had no `hostPath` volume for the log directory.
At start-up the API server opens the log file, finds no such directory in its filesystem, and exits:
*ensureLogFile: open /var/log/kubernetes/audit/audit.log: no such file or directory*. The kubelet restarts
it forever, and every client gets *connection refused*.

**Diagnosis**
```
./lab node cp1
sudo crictl ps -a --name kube-apiserver            # Exited, restarting
sudo crictl logs $(sudo crictl ps -a --name kube-apiserver -q | head -1) 2>&1 | tail -5
sudo grep -n -A3 'audit' /etc/kubernetes/manifests/kube-apiserver.yaml
sudo journalctl -u kubelet --since -5min | grep -i apiserver
```

**Fix**: a hostPath volume + mount for the log directory:
```yaml
    volumeMounts:
    - {name: audit-log, mountPath: /var/log/kubernetes/audit}
  volumes:
  - {name: audit-log, hostPath: {path: /var/log/kubernetes/audit, type: DirectoryOrCreate}}
```

**Interview notes**
- Every file a static pod reads or writes on the node needs a `hostPath` (encryption config, audit policy,
  audit log, webhook kubeconfigs). This is the most common way to break a control-plane manifest.
- Edit **outside** `/etc/kubernetes/manifests` and move the file in. Editors' swap/backup files there become
  extra static pods, and a half-written file is applied at once.
- Audit levels: `None`, `Metadata` (who/what/when, no bodies), `Request`, `RequestResponse`. Logging Secrets
  above `Metadata` writes secret values to disk.
- With kubeadm, put these in `ClusterConfiguration.apiServer.extraArgs` / `extraVolumes` too, or the next
  `kubeadm upgrade` regenerates the manifest without them.
