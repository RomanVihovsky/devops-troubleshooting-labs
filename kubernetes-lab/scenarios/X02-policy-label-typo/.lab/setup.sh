# X02: the allowed client label is misspelled (frontned)
kns shopx
for a in backend frontend; do
  kx -n shopx create deployment "$a" --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); a = d["metadata"]["name"]
d["spec"]["selector"]["matchLabels"] = {"app": a, "tier": "x02"}; d["spec"]["template"]["metadata"]["labels"] = {"app": a, "tier": "x02"}
print(yaml.safe_dump(d))' | ka -f -
done
kx -n shopx create service clusterip backend --tcp=8080:8080 --dry-run=client -o yaml | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); d["spec"]["selector"] = {"app": "backend"}; print(yaml.safe_dump(d))' | ka -f -
wait_rollout shopx deploy/backend; wait_rollout shopx deploy/frontend
ka -f backend-allow.yaml
! tcp_ok_as shopx app=frontend backend.shopx.svc:8080 || die "the frontend still connects"
