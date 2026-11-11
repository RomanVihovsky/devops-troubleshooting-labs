# L10: a static pod manifest left on w2 (netdebug, hostNetwork) - the mirror pod comes back after every delete
nxi k8s-w2 >/dev/null <<'__X__'
set -eu
cat > /etc/kubernetes/manifests/netdebug.yaml <<'YML'
apiVersion: v1
kind: Pod
metadata:
  name: netdebug
  namespace: default
  labels: {app: netdebug}
spec:
  hostNetwork: true
  containers:
    - name: debug
      image: docker.io/library/busybox:1.37
      command: ["sh", "-c", "while true; do sleep 3600; done"]
YML
__X__
mirror() { kx -n default get pod netdebug-k8s-w2 >/dev/null 2>&1; }
retry 120 mirror || die "no mirror pod"
