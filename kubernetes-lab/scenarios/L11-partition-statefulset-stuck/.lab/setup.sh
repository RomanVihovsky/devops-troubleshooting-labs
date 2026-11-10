# L11: db-0 and one web pod on k8s-w3 (short eviction timeouts for the lab), then w3 is cut off
kns inventory
ka -f - <<YML
apiVersion: apps/v1
kind: StatefulSet
metadata: {name: db, namespace: inventory}
spec:
  serviceName: db
  replicas: 1
  selector: {matchLabels: {app: db}}
  template:
    metadata: {labels: {app: db}}
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - {weight: 100, preference: {matchExpressions: [{key: kubernetes.io/hostname, operator: In, values: [k8s-w3]}]}}
      tolerations:
        - {key: node.kubernetes.io/unreachable, operator: Exists, effect: NoExecute, tolerationSeconds: 20}
        - {key: node.kubernetes.io/not-ready, operator: Exists, effect: NoExecute, tolerationSeconds: 20}
      containers:
        - name: db
          image: $BUSYBOX_IMAGE
          command: [sh, -c, 'touch /data/orders.db; while true; do sleep 5; done']
          readinessProbe: {exec: {command: [test, -f, /data/orders.db]}, periodSeconds: 3}
          volumeMounts: [{name: data, mountPath: /data}]
  volumeClaimTemplates:
    - metadata: {name: data}
      spec: {accessModes: [ReadWriteOnce], storageClassName: nfs, resources: {requests: {storage: 64Mi}}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: web, namespace: inventory}
spec:
  replicas: 2
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web}}
    spec:
      topologySpreadConstraints:
        - {maxSkew: 1, topologyKey: kubernetes.io/hostname, whenUnsatisfiable: ScheduleAnyway, labelSelector: {matchLabels: {app: web}}}
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - {weight: 50, preference: {matchExpressions: [{key: kubernetes.io/hostname, operator: In, values: [k8s-w3]}]}}
      tolerations:
        - {key: node.kubernetes.io/unreachable, operator: Exists, effect: NoExecute, tolerationSeconds: 20}
        - {key: node.kubernetes.io/not-ready, operator: Exists, effect: NoExecute, tolerationSeconds: 20}
      containers:
        - {name: web, image: registry.lab:5000/lab/labapp:1.4}
YML
kx -n inventory rollout status sts/db --timeout=180s >/dev/null
wait_rollout inventory deploy/web
[ "$(kx -n inventory get pod db-0 -o jsonpath='{.spec.nodeName}')" = k8s-w3 ] || die "db-0 did not land on k8s-w3"
kx -n inventory exec db-0 -- sh -c 'echo "order-42 shipped" > /data/orders.db'
remember l11_pvc "$(kx -n inventory get pvc data-db-0 -o jsonpath='{.metadata.uid}')"
fault_partition k8s-w3
stuck() { [ -n "$(kx -n inventory get pod db-0 -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)" ]; }
retry 240 stuck || die "db-0 was never marked for deletion"
