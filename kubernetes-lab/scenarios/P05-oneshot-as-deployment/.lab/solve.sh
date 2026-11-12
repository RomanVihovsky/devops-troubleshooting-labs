kx -n orders delete deploy orders-migrate >/dev/null
kx apply -f - >/dev/null <<'YML'
apiVersion: batch/v1
kind: Job
metadata: {name: orders-migrate, namespace: orders}
spec:
  backoffLimit: 3
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: registry.lab:5000/lab/labapp:1.4
          command: [labapp, migrate]
YML
kx -n orders wait --for=condition=complete job/orders-migrate --timeout=120s >/dev/null || true
