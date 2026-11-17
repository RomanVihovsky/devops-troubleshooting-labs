# N12: a "host firewall" table on w3 drops all UDP from the node network except DNS/NTP - including VXLAN (4789)
kns meshcheck
ka -f - <<'YML'
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: echo, namespace: meshcheck}
spec:
  selector: {matchLabels: {app: echo}}
  template:
    metadata: {labels: {app: echo}}
    spec:
      containers:
        - name: echo
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: meshcheck}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
          resources: {requests: {cpu: 10m, memory: 24Mi}}
YML
ds_ready() { [ "$(kx -n meshcheck get ds echo -o jsonpath='{.status.numberReady}')" = 3 ]; }
retry 120 ds_ready || die "meshcheck is not on all 3 workers"
ns_matrix meshcheck app=echo || die "the mesh is broken before the fault"
nxi k8s-w3 >/dev/null <<'__X__'
set -eu
nft -f - <<'EOF'
table inet host_firewall {
  chain input {
    type filter hook input priority -10; policy accept;
    ip saddr 192.168.56.0/24 ct state != { established, related } udp dport != { 53, 123, 323 } counter drop comment "HARD-221: only DNS/NTP over UDP on the host network"
  }
}
EOF
__X__
broken() { ! ns_matrix meshcheck app=echo; }
retry 60 broken || die "cross-node traffic still works"
