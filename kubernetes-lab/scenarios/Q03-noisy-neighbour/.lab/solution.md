# Q03 - finding a noisy neighbour

**How**: `kubectl top pods -A --sort-by=cpu` (or `-n tenants`), cross-checked with the pods on the node
(`--field-selector spec.nodeName=k8s-w1`) and `crictl stats` on the node. One tenant ran background "indexer"
threads (`INDEXER_WORKERS`) that spin forever.

**Interview notes**
- `kubectl top` = metrics-server: the last ~15 s, no history. For "since this morning" use Prometheus
  (`rate(container_cpu_usage_seconds_total[5m])` by pod).
- Noisy neighbours exist because requests are low and limits absent. CPU **requests** set the share under
  contention (cpu.weight), so a pod with a proper request keeps its share. Limits cap the burner but also
  throttle it (R03).
- Memory neighbours behave differently: no throttling, the kernel/kubelet evicts or OOM-kills (R04).
- Before killing: who owns it (labels, namespace annotations), is it doing legitimate work (a reindex)?
