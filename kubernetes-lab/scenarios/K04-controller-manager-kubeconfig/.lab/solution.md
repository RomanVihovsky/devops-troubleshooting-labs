# K04 - the controller-manager can't read its kubeconfig

**Root cause**: `--kubeconfig=/etc/kubernetes/controller-manager.kubeconfig` - the file is
`controller-manager.conf`, and the manifest only mounts that one into the container. The controller-manager
exits at start; nothing reconciles Deployments, ReplicaSets, Jobs, endpoints, node lifecycle, ...

**Diagnosis**: `kubectl -n kube-system get pods` (CrashLoopBackOff), on cp1 `crictl logs <id>` ("stat
/etc/kubernetes/controller-manager.kubeconfig: no such file or directory").

**Fix**: the right path in the manifest.

**Interview notes**
- API objects are just data; controllers make them happen. Deployment → ReplicaSet → Pods are two
  controllers in kube-controller-manager; scheduling is a separate component (K03).
- A static pod sees only what its `volumes`/`volumeMounts` give it: a correct path on the host is not
  enough if it isn't mounted.
- Symptoms of a dead controller-manager: no new RS/pods, no endpoint updates, nodes never marked
  NotReady, no garbage collection, ServiceAccount tokens still work (that's the API server).
