kx -n payments-team patch rolebinding team-edit --type json -p '[{"op":"replace","path":"/subjects/0/name","value":"payments-devs"}]' >/dev/null
python3 - payments.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
for d in docs:
    if d["kind"] != "Deployment":
        continue
    s = d["spec"]["template"]["spec"]
    s["securityContext"] = {"runAsNonRoot": True, "seccompProfile": {"type": "RuntimeDefault"}}
    for c in s["containers"]:
        c["securityContext"] = {"allowPrivilegeEscalation": False, "capabilities": {"drop": ["ALL"]}}
        c["resources"] = {"requests": {"cpu": "50m", "memory": "64Mi"}, "limits": {"memory": "128Mi"}}
docs.append({"apiVersion": "networking.k8s.io/v1", "kind": "NetworkPolicy",
             "metadata": {"name": "allow-dns", "namespace": "payments-team"},
             "spec": {"podSelector": {}, "policyTypes": ["Egress"], "egress": [{"to": [{"namespaceSelector": {"matchLabels": {"kubernetes.io/metadata.name": "kube-system"}},
                      "podSelector": {"matchLabels": {"k8s-app": "kube-dns"}}}], "ports": [{"port": 53, "protocol": "UDP"}, {"port": 53, "protocol": "TCP"}]}]}})
docs.append({"apiVersion": "networking.k8s.io/v1", "kind": "NetworkPolicy",
             "metadata": {"name": "api-to-ledger", "namespace": "payments-team"},
             "spec": {"podSelector": {"matchLabels": {"app": "ledger"}}, "policyTypes": ["Ingress"],
                      "ingress": [{"from": [{"podSelector": {"matchLabels": {"app": "payments-api"}}}], "ports": [{"port": 8080}]}]}})
docs.append({"apiVersion": "networking.k8s.io/v1", "kind": "NetworkPolicy",
             "metadata": {"name": "api-egress-ledger", "namespace": "payments-team"},
             "spec": {"podSelector": {"matchLabels": {"app": "payments-api"}}, "policyTypes": ["Egress"],
                      "egress": [{"to": [{"podSelector": {"matchLabels": {"app": "ledger"}}}], "ports": [{"port": 8080}]}]}})
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
KUBECONFIG="$STATE_DIR/scenario.b03-tina.kubeconfig" kubectl apply -f payments.yaml >/dev/null
retry 150 deploy_ready payments-team payments-api 2 || true
