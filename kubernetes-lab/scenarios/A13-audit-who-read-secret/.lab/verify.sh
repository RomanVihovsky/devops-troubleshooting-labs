source "$SCN/.lab/facts.sh"
policy_ok() {
  nx "$CP" 'cat /etc/kubernetes/audit/policy.yaml' </dev/null 2>/dev/null | python3 -c 'import sys, yaml
p = yaml.safe_load(sys.stdin) or {}
for r in p.get("rules", []):
    res = [x for g in r.get("resources", []) for x in g.get("resources", [])] if r.get("resources") else ["*"]
    if "secrets" in res or "*" in res:
        sys.exit(0 if r.get("level") == "Metadata" else 1)
sys.exit(1)'
}
audit_on() { nx "$CP" 'grep -q -- "--audit-policy-file" /etc/kubernetes/manifests/kube-apiserver.yaml' </dev/null; }
check "the ServiceAccount" answered service_account system:serviceaccount:ci:reporter
check "the pod it ran in" answered pod "$(a13_pod)"
check "the human user" answered user bob
check "auditing is still on" audit_on
check "the policy logs Secrets at Metadata (no values)" policy_ok
verdict
