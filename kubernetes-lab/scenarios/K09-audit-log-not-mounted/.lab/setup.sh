# K09: audit flags + the policy mounted, but no hostPath for the log directory -> "no such file or directory"
nxi "$CP" >/dev/null <<'__X__'
set -eu
mkdir -p /etc/kubernetes/audit
cat > /etc/kubernetes/audit/policy.yaml <<'EOF2'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages: [RequestReceived]
rules:
  - {level: Metadata, resources: [{group: "", resources: [secrets, configmaps]}]}
  - {level: None}
EOF2
python3 - <<'PY'
import yaml
f = "/etc/kubernetes/manifests/kube-apiserver.yaml"
d = yaml.safe_load(open(f))
c = d["spec"]["containers"][0]
c["command"] += ["--audit-policy-file=/etc/kubernetes/audit/policy.yaml",
                 "--audit-log-path=/var/log/kubernetes/audit/audit.log",
                 "--audit-log-maxage=7", "--audit-log-maxbackup=2", "--audit-log-maxsize=50"]
c["volumeMounts"].append({"name": "audit-policy", "mountPath": "/etc/kubernetes/audit", "readOnly": True})
d["spec"]["volumes"].append({"name": "audit-policy", "hostPath": {"path": "/etc/kubernetes/audit", "type": "DirectoryOrCreate"}})
yaml.safe_dump(d, open("/var/tmp/kube-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
api_down() { ! KX_TIMEOUT=5s kx get --raw /readyz >/dev/null 2>&1; }
retry 180 api_down || die "the API server did not go down"
