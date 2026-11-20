# O11: widgets were written as v1; the "upgrade" stops serving v1 (objects stay stored as v1)
crd_ok() { [ "$(kx get crd widgets.example.lab -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)" = True ]; }
python3 - widgets-crd.yaml <<'PY' | ka -f -
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
v1 = d["spec"]["versions"][0]; v1["served"] = True; v1["storage"] = True
d["spec"]["versions"] = [v1]
print(yaml.safe_dump(d, sort_keys=False))
PY
retry 60 crd_ok || die "the v1 CRD is not established"
kns factory
for w in gear:red:3 bolt:blue:1 spring:green:7; do
  IFS=: read -r n c s <<<"$w"
  ka -f - <<YML
apiVersion: example.lab/v1
kind: Widget
metadata: {name: $n, namespace: factory}
spec: {color: $c, size: $s}
YML
done
ka -f widgets-crd.yaml
v1_gone() { ! kx get --raw /apis/example.lab/v1/namespaces/factory/widgets >/dev/null 2>&1; }
retry 60 v1_gone || die "v1 is still served"
ka -f - <<'YML'
apiVersion: v1
kind: ServiceAccount
metadata: {name: widget-reporter, namespace: factory}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: widget-reader, namespace: factory}
rules:
  - {apiGroups: [example.lab], resources: [widgets], verbs: [get, list]}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: widget-reporter, namespace: factory}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: widget-reader}
subjects: [{kind: ServiceAccount, name: widget-reporter, namespace: factory}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: widget-reporter, namespace: factory}
spec:
  replicas: 1
  selector: {matchLabels: {app: widget-reporter}}
  template:
    metadata: {labels: {app: widget-reporter}}
    spec:
      serviceAccountName: widget-reporter
      containers:
        - name: reporter
          image: registry.lab:5000/lab/labapp:1.4
          command: ["sh", "-c"]
          args:
            - |
              sa=/var/run/secrets/kubernetes.io/serviceaccount
              while true; do
                if labapp get -q -H "Authorization: Bearer $(cat $sa/token)" --cacert $sa/ca.crt \
                     https://kubernetes.default.svc/apis/example.lab/v1/namespaces/factory/widgets > /tmp/report.json; then
                  echo "report: $(grep -o '"name"' /tmp/report.json | wc -l) widgets"; touch /tmp/ok
                else
                  echo "ERROR listing widgets.v1.example.lab"; rm -f /tmp/ok
                fi
                sleep 10
              done
          readinessProbe:
            exec: {command: ["test", "-f", "/tmp/ok"]}
            periodSeconds: 5
YML
erroring() { local o; o=$(kx -n factory logs deploy/widget-reporter --tail=5 2>/dev/null) || true; grep -q ERROR <<<"$o"; }
retry 90 erroring || die "widget-reporter doesn't fail"
