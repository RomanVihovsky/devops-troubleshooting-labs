kns monitor
ka -f - <<'YML'
apiVersion: v1
kind: ServiceAccount
metadata: {name: scraper, namespace: monitor}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: scraper, namespace: monitor}
spec:
  replicas: 1
  selector: {matchLabels: {app: scraper}}
  template:
    metadata: {labels: {app: scraper}}
    spec:
      serviceAccountName: scraper
      containers:
        - name: scraper
          image: docker.io/library/busybox:1.37
          command: [sh, -c, 'while true; do wget -q -O /dev/null --no-check-certificate --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc/api/v1/namespaces/monitor/pods 2>&1 | head -1; sleep 15; done']
YML
ka -f rbac.yaml
