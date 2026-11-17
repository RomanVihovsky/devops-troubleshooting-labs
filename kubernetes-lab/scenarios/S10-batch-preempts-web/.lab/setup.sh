# S10: batch-high (1e6, PreemptLowerPriority) + a Job that doesn't fit next to storefront on k8s-w2 -> preemption
kns storefront
# size the requests from w2's free allocatable memory: 3 x 28 % for storefront, 45 % for the batch -> no room
free=$(kx get pods -A --field-selector spec.nodeName=k8s-w2,status.phase!=Succeeded,status.phase!=Failed -o json \
  | python3 -c '
import json, re, subprocess, sys
u = {"Ki": 2**10, "Mi": 2**20, "Gi": 2**30, "K": 1e3, "M": 1e6, "G": 1e9}
def b(q):
    m = re.fullmatch(r"([0-9.]+)([KMG]i?)?", q or "0"); return float(m.group(1)) * u.get(m.group(2) or "", 1)
used = sum(b(c.get("resources", {}).get("requests", {}).get("memory")) for p in json.load(sys.stdin)["items"] for c in p["spec"]["containers"])
alloc = b(json.loads(subprocess.check_output(["kubectl", "get", "node", "k8s-w2", "-o", "json"]))["status"]["allocatable"]["memory"])
print(int((alloc - used) / 2**20))')
[ "$free" -gt 1000 ] || die "k8s-w2 has only ${free}Mi of unrequested memory"
web=$((free * 28 / 100)); batch=$((free * 45 / 100))
remember s10_web "${web}Mi"; remember s10_batch "${batch}Mi"
ka -f - <<YML
apiVersion: apps/v1
kind: Deployment
metadata: {name: storefront, namespace: storefront}
spec:
  replicas: 3
  selector: {matchLabels: {app: storefront}}
  template:
    metadata: {labels: {app: storefront}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w2}
      containers:
        - name: web
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: storefront}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
          resources: {requests: {cpu: 20m, memory: ${web}Mi}}
YML
wait_rollout storefront deploy/storefront
cat > nightly-batch.yaml <<YML
apiVersion: batch/v1
kind: Job
metadata:
  name: nightly-batch
  namespace: storefront
spec:
  backoffLimit: 0
  template:
    metadata:
      labels: {app: nightly-batch}
    spec:
      priorityClassName: batch-high
      restartPolicy: Never
      nodeSelector: {kubernetes.io/hostname: k8s-w2}      # needs the local SSD cache
      containers:
        - name: batch
          image: registry.lab:5000/lab/labapp:1.4
          command: ["sh", "-c", "echo crunching; sleep 900"]
          resources: {requests: {cpu: 20m, memory: ${batch}Mi}}
YML
cp nightly-batch.yaml "$STATE_DIR/scenario.s10-batch.yaml"
ka -f priority.yaml
ka -f nightly-batch.yaml
preempted() { [ -n "$(kx -n storefront get events --field-selector reason=Preempted -o name 2>/dev/null)" ]; }
retry 120 preempted || die "the batch never preempted a storefront pod"
