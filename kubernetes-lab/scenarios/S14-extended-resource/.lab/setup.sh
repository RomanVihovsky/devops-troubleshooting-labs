# S14: a pod requests example.com/gpu: 1; no node advertises it
kns ml
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: trainer, namespace: ml}
spec:
  replicas: 1
  selector: {matchLabels: {app: trainer}}
  template:
    metadata: {labels: {app: trainer}}
    spec:
      containers:
        - name: trainer
          image: registry.lab:5000/lab/labapp:1.4
          resources:
            requests: {cpu: 50m, memory: 64Mi, example.com/gpu: 1}
            limits: {example.com/gpu: 1}
YML
pending() { kx -n ml get events -o jsonpath='{.items[*].message}' | grep -q 'Insufficient example.com/gpu'; }
retry 60 pending || die "trainer not Pending on the gpu"
