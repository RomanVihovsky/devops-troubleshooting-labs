python3 - storefront.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
for d in docs:
    if d["kind"] == "Service" and d["metadata"]["name"] == "catalog":
        d["spec"]["selector"] = {"app": "catalog"}
    if d["kind"] == "Deployment" and d["metadata"]["name"] == "catalog":
        d["spec"]["template"]["spec"]["containers"][0]["resources"]["requests"] = {"cpu": "100m", "memory": "64Mi"}
    if d["kind"] == "PodDisruptionBudget":
        d["spec"].pop("minAvailable", None); d["spec"]["maxUnavailable"] = 1
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
cat >> policies.yaml <<'YML'
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-dns, namespace: bf}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}, podSelector: {matchLabels: {k8s-app: kube-dns}}}]
      ports: [{port: 53, protocol: UDP}, {port: 53, protocol: TCP}]
YML
kx -n bf delete pdb catalog >/dev/null 2>&1 || true     # minAvailable -> maxUnavailable is a field swap
ka -f storefront.yaml
ka -f policies.yaml
wait_rollout bf deploy/catalog 240
