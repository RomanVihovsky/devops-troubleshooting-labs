kx -n thumbs delete deploy thumbs --wait=true >/dev/null
kx -n thumbs delete pvc thumbs-cache --wait=false >/dev/null
cat > thumbs.yaml <<'YML'
apiVersion: apps/v1
kind: StatefulSet
metadata: {name: thumbs, namespace: thumbs}
spec:
  serviceName: thumbs
  replicas: 2
  selector: {matchLabels: {app: thumbs}}
  template:
    metadata: {labels: {app: thumbs}}
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - {topologyKey: kubernetes.io/hostname, labelSelector: {matchLabels: {app: thumbs}}}
      containers:
        - name: app
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: thumbs}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
          volumeMounts: [{name: cache, mountPath: /cache}]
  volumeClaimTemplates:
    - metadata: {name: cache}
      spec: {accessModes: [ReadWriteOnce], storageClassName: local-path, resources: {requests: {storage: 64Mi}}}
YML
kx apply -f thumbs.yaml >/dev/null
kx -n thumbs rollout status sts/thumbs --timeout=240s >/dev/null
