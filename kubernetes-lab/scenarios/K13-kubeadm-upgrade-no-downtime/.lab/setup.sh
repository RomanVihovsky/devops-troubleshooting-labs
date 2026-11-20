# K13: the cluster rebuilt bare at 1.36 (PKI kept); storefront with an over-strict PDB; a prober on gw
cluster_bare_build "$K8S_BUILD_VERSION"
remember k13_target "$K8S_VERSION"
kx create namespace storefront --dry-run=client -o yaml | kx apply -f - >/dev/null
kx apply -f - >/dev/null <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: storefront, namespace: storefront}
spec:
  replicas: 3
  selector: {matchLabels: {app: storefront}}
  strategy: {rollingUpdate: {maxSurge: 1, maxUnavailable: 0}}
  template:
    metadata: {labels: {app: storefront}}
    spec:
      topologySpreadConstraints:
        - {maxSkew: 1, topologyKey: kubernetes.io/hostname, whenUnsatisfiable: ScheduleAnyway, labelSelector: {matchLabels: {app: storefront}}}
      containers:
        - name: web
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: storefront}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 2}
          lifecycle: {preStop: {sleep: {seconds: 5}}}
---
apiVersion: v1
kind: Service
metadata: {name: storefront, namespace: storefront}
spec:
  type: NodePort
  selector: {app: storefront}
  ports: [{port: 8080, targetPort: 8080, nodePort: 30080}]
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: {name: storefront, namespace: storefront}
spec:
  minAvailable: 3          # "never fewer than 3"
  selector: {matchLabels: {app: storefront}}
YML
retry 240 deploy_ready storefront storefront 3 || die "storefront not Ready on the bare cluster"
outage_probe start k13 "http://$(node_ip "$CP"):30080/ready"
sleep 5
[ "$(outage_probe gaps k13)" = 0 ] || die "the prober fails before the upgrade"
