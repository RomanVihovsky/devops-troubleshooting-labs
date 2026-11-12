# R02 - metrics-server can't find the kubelets

**Root cause**: the flag became `--kubelet-preferred-address-types=Hostname`. metrics-server then scraped
`https://k8s-w1:10250/...`. Pods resolve names through CoreDNS, which doesn't know node hostnames, so every
scrape failed with *no such host*. No metrics meant the `metrics.k8s.io` API had nothing to serve: `kubectl top`
failed and every HPA went `<unknown>`.

**Diagnosis**
```
kubectl top nodes
kubectl get apiservice v1beta1.metrics.k8s.io           # Available? (the aggregation layer)
kubectl -n kube-system logs deploy/metrics-server | grep -m3 -i 'no such host'
kubectl -n kube-system get deploy metrics-server -o jsonpath='{.spec.template.spec.containers[0].args}'; echo
```

**Fix**: `--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname` (the chart's default). The kubelet
serving certificates (serverTLSBootstrap) carry the node IPs as SANs, so verification keeps working.

**Interview notes**
- The famous "fix" `--kubelet-insecure-tls` is for kubelets with self-signed serving certs. It makes the
  metrics path open to a man in the middle. Here it isn't needed: approve the kubelets' serving CSRs instead.
- Path: API server (aggregation layer, APIService) → metrics-server Service → metrics-server → each
  kubelet's `/metrics/resource`. Check them in that order.
- metrics-server is for autoscaling, not monitoring: no history, 15 s resolution.
