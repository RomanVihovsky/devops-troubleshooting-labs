# X08: namespace batch is pinned to a /29 Calico pool (8 addresses) and asks for 12 pods
ka -f batch-pool.yaml
kns batch
kx annotate namespace batch --overwrite 'cni.projectcalico.org/ipv4pools=["batch-pool"]' >/dev/null
remember x08_default "$(kx get ippools.crd.projectcalico.org default-ipv4-ippool -o jsonpath='{.spec.cidr} {.spec.blockSize}')"
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: crunch, namespace: batch}
spec:
  replicas: 12
  selector: {matchLabels: {app: crunch}}
  template:
    metadata: {labels: {app: crunch}}
    spec:
      containers:
        - name: crunch
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: crunch}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
          resources: {requests: {cpu: 10m, memory: 24Mi}}
YML
stuck() { local o; o=$(kx -n batch get events --field-selector reason=FailedCreatePodSandBox -o jsonpath='{.items[*].message}' 2>/dev/null) || true; grep -qiE 'No IPs available|allocat|no more free|exhaust' <<<"$o"; }
retry 180 stuck || die "no pod failed to get an IP"
! deploy_ready batch crunch 12 || die "all 12 pods got an IP"
