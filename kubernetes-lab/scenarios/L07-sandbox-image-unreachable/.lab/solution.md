# L07 - the pause image comes first

**Root cause**: before any container of a pod runs, containerd creates the pod **sandbox** (network namespace +
"pause" container) from its configured sandbox image. The hardening changed it on w2 to
`registry.internal.corp/k8s/pause:3.10.2`, which doesn't resolve. Every new pod on w2 fails with
*FailedCreatePodSandBox ... failed to get sandbox image "registry.internal.corp/..."*; the app image is irrelevant,
and already-running pods keep their existing sandboxes.

**Diagnosis**
```
kubectl -n shipping describe pod <pod>                  # FailedCreatePodSandBox: ... sandbox image ...
./lab node w2
  grep -n -A2 pinned_images /etc/containerd/config.toml
  crictl images | grep pause                            # registry.k8s.io/pause:3.10.2 is cached
  crictl info | jq .config.sandboxImage                 # what containerd uses
```

**Fix**: set `sandbox = 'registry.k8s.io/pause:3.10.2'` (in containerd 2.x under
`[plugins.'io.containerd.cri.v1.images'.pinned_images]`; 1.x: `sandbox_image` in the CRI plugin) and restart
containerd. Alternatively push pause into the new registry first, then switch.

**Interview notes**
- The pause image is **pinned**, so image GC never deletes it - unless its reference changes.
- Air-gapped clusters must mirror pause too (`kubeadm config images list` shows the version kubeadm expects).
- Kubelet `--pod-infra-container-image` is ignored with remote runtimes since 1.27: the runtime's config is what
  counts.
