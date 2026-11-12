# Q03: five tenant services on k8s-w1, one of them (chosen at random) with background CPU burners
kns tenants
names=(ledger-sync quote-cache mailer pdf-render geo-lookup)
burner=${names[$((RANDOM % 5))]}
remember q03_burner "$burner"
for n in "${names[@]}"; do
  w=0; [ "$n" = "$burner" ] && w=2
  ka -f - <<YML
apiVersion: apps/v1
kind: Deployment
metadata: {name: $n, namespace: tenants}
spec:
  replicas: 1
  selector: {matchLabels: {app: $n}}
  template:
    metadata: {labels: {app: $n}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w1}
      containers:
        - name: app
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: $n}, {name: INDEXER_WORKERS, value: "$w"}]
          resources: {requests: {cpu: 20m, memory: 64Mi}}
YML
done
for n in "${names[@]}"; do wait_rollout tenants "deploy/$n"; done
visible() { kx -n tenants top pods --no-headers 2>/dev/null | sort -k2 -n -r | head -1 | grep -q "^$burner-"; }
retry 120 visible || die "the burner does not show in kubectl top"
