# K10 - a static pod manifest the kubelet can't parse

**Root cause**: the new `- --v=2` line was indented with a **tab**. YAML forbids tabs for indentation, so the
kubelet failed to decode `/etc/kubernetes/manifests/kube-scheduler.yaml`. It treats an unparseable file as
"no pod": it stopped the running scheduler and created nothing. Without a scheduler, new pods stay Pending
with no events (only the scheduler writes "FailedScheduling").

**Diagnosis**
```
kubectl -n kube-system get pods | grep scheduler                     # nothing
./lab node cp1
sudo journalctl -u kubelet --since -10min | grep -iE 'scheduler|could not process|yaml'
sudo cat -A /etc/kubernetes/manifests/kube-scheduler.yaml | grep -n 'v=2'   # ^I = tab
python3 -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))' /etc/kubernetes/manifests/kube-scheduler.yaml
```

**Fix**: indent the flag with spaces like its neighbours, then move the file back into place (edit a copy
outside the directory).

**Interview notes**
- "Pending without events" points at the scheduler. "No pod at all" for a static pod points at the
  manifest: a parse error, a wrong filename, or the wrong `staticPodPath` in the kubelet config.
- The kubelet watches the directory, so changes apply within seconds. A broken file removes the pod.
- `kubectl -n kube-system get pod kube-scheduler-<node>` is only a *mirror pod*: deleting it changes nothing,
  and editing it is impossible. The source of truth is the file.
- Lint before you move the file in: `python3 -c 'import yaml...'`, or `kubectl apply --dry-run=client -f`.
