source "$SCN/.lab/facts.sh"
python3 - <<'PY'
import yaml
docs = [d for d in yaml.safe_load_all(open("t06.yaml")) if d]
for d in docs:
    if d["kind"] == "Service" and d["metadata"]["name"] == "hello-lb":
        d["metadata"]["annotations"] = {"metallb.io/loadBalancerIPs": "192.168.56.210"}
        d["spec"]["type"] = "LoadBalancer"
docs.append({"apiVersion": "networking.k8s.io/v1", "kind": "Ingress", "metadata": {"name": "hello", "namespace": "t06"},
  "spec": {"rules": [{"host": "t06.lab", "http": {"paths": [{"path": "/", "pathType": "Prefix",
    "backend": {"service": {"name": "hello", "port": {"number": 80}}}}]}}]}})
docs.append({"apiVersion": "gateway.networking.k8s.io/v1", "kind": "HTTPRoute", "metadata": {"name": "hello", "namespace": "t06"},
  "spec": {"parentRefs": [{"name": "traefik-gateway", "namespace": "traefik"}], "hostnames": ["t06-gw.lab"],
    "rules": [{"backendRefs": [{"name": "hello", "port": 80}]}]}})
yaml.safe_dump_all(docs, open("t06.yaml", "w"), sort_keys=False)
PY
kx apply -f t06.yaml >/dev/null
wait_rollout t06 deploy/hello
l2() { [ -n "$(f_l2_node)" ]; }
retry 60 l2 || true
printf 'l2_node: %s\n' "$(f_l2_node)" > answers.yaml
