## Hint 1
`./lab node cp1`, then `sudo crictl ps -a --name kube-apiserver` and `sudo crictl logs <id>` (the newest one).
What does it fail to open?

## Hint 2
A static pod sees the node's filesystem only through `hostPath` volumes. The policy has a volume + mount;
the log directory has none, so the path doesn't exist **inside** the container.

## Hint 3
In `/etc/kubernetes/manifests/kube-apiserver.yaml` add a volume
`{name: audit-log, hostPath: {path: /var/log/kubernetes/audit, type: DirectoryOrCreate}}` and a matching
`volumeMounts` entry (`mountPath: /var/log/kubernetes/audit`, not read-only). Edit a copy outside
`manifests/` and move it back in one step.
