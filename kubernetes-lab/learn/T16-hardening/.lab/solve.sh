nxi "$CP" >/dev/null <<'__X__'
set -eu
mkdir -p /etc/kubernetes/enc /etc/kubernetes/audit /var/log/kubernetes/audit
key=$(head -c 32 /dev/urandom | base64)
cat > /etc/kubernetes/enc/enc.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources: [secrets]
    providers:
      - aescbc:
          keys:
            - {name: key1, secret: $key}
      - identity: {}
EOF
chmod 600 /etc/kubernetes/enc/enc.yaml
cat > /etc/kubernetes/audit/policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages: [RequestReceived]
rules:
  - {level: Metadata, resources: [{group: "", resources: [secrets]}]}
  - {level: None}
EOF
python3 - <<'PY'
import yaml
f = "/etc/kubernetes/manifests/kube-apiserver.yaml"
d = yaml.safe_load(open(f))
c = d["spec"]["containers"][0]
c["command"] += ["--encryption-provider-config=/etc/kubernetes/enc/enc.yaml",
                 "--audit-policy-file=/etc/kubernetes/audit/policy.yaml",
                 "--audit-log-path=/var/log/kubernetes/audit/audit.log",
                 "--audit-log-maxage=7", "--audit-log-maxbackup=2", "--audit-log-maxsize=50"]
c["volumeMounts"] += [{"name": "k8s-enc", "mountPath": "/etc/kubernetes/enc", "readOnly": True},
                      {"name": "k8s-audit-policy", "mountPath": "/etc/kubernetes/audit", "readOnly": True},
                      {"name": "k8s-audit-log", "mountPath": "/var/log/kubernetes/audit"}]
d["spec"]["volumes"] += [{"name": "k8s-enc", "hostPath": {"path": "/etc/kubernetes/enc", "type": "DirectoryOrCreate"}},
                         {"name": "k8s-audit-policy", "hostPath": {"path": "/etc/kubernetes/audit", "type": "DirectoryOrCreate"}},
                         {"name": "k8s-audit-log", "hostPath": {"path": "/var/log/kubernetes/audit", "type": "DirectoryOrCreate"}}]
yaml.safe_dump(d, open("/var/tmp/kube-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
sleep 20   # kubelet notices the manifest change and restarts the API server
retry 240 kx get --raw /readyz || die "API server not back after the hardening"
has_flag() { kx -n kube-system get pod "kube-apiserver-$CP" -o jsonpath='{.spec.containers[0].command}' | grep -q encryption-provider-config; }
retry 120 has_flag || true
kx get secrets -A -o json | kx replace -f - >/dev/null 2>&1 || true
kx label ns t16 pod-security.kubernetes.io/enforce=restricted --overwrite >/dev/null
