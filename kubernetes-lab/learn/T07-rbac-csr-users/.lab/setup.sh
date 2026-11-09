# T07: namespace t07 with a pod to read (and a secret that jane must not read)
kns t07
kx delete csr t07-jane --ignore-not-found >/dev/null 2>&1
ka -f - <<'YML'
apiVersion: v1
kind: Pod
metadata: {name: app, namespace: t07, labels: {app: app}}
spec:
  containers:
    - {name: app, image: docker.io/library/busybox:1.37, command: [sh, -c, 'while true; do echo tick; sleep 10; done']}
---
apiVersion: v1
kind: Secret
metadata: {name: db-password, namespace: t07}
stringData: {password: do-not-read-me}
YML
kx -n t07 wait --for=condition=Ready pod/app --timeout=120s >/dev/null
