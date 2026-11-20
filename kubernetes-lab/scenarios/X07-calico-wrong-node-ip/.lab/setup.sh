# X07: calico-node IP_AUTODETECTION_METHOD=can-reach=1.1.1.1 (follows the default route = the NAT NIC) + OnDelete;
# only w3's pod restarted -> w3 registers 10.0.2.15 (first-found would pick the host-only NIC on these VMs)
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
kx -n kube-system patch ds calico-node --type strategic -p '{"spec":{"updateStrategy":{"type":"OnDelete","rollingUpdate":null},"template":{"spec":{"containers":[{"name":"calico-node","env":[{"name":"IP_AUTODETECTION_METHOD","value":"can-reach=1.1.1.1"}]}]}}}}' >/dev/null
kx -n kube-system delete pod -l k8s-app=calico-node --field-selector spec.nodeName=k8s-w3 --wait=true >/dev/null
nat() { [ "$(kx get node k8s-w3 -o jsonpath='{.metadata.annotations.projectcalico\.org/IPv4Address}')" = 10.0.2.15/24 ]; }
retry 180 nat || die "w3 did not register the NAT address"
broken() { ! ns_matrix meshcheck app=echo; }
retry 60 broken || die "cross-node traffic still works"
