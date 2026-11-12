# X01: default-deny (in + out) and an allow client -> backend, but no DNS egress
kns zt
for a in backend client; do
  kx -n zt create deployment "$a" --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); a = d["metadata"]["name"]; c = d["spec"]["template"]["spec"]["containers"][0]
c["env"] = [{"name": "APP_NAME", "value": a}] + ([{"name": "UPSTREAM_URL", "value": "http://backend.zt.svc:8080/"}] if a == "client" else [])
print(yaml.safe_dump(d))' | ka -f -
done
kx -n zt create service clusterip backend --tcp=8080:8080 --dry-run=client -o yaml | ka -f -
wait_rollout zt deploy/backend; wait_rollout zt deploy/client
ka -f policies.yaml
remember x01_deny "$(kx -n zt get networkpolicy default-deny -o jsonpath='{.spec}')"
broken() { ! pods_get zt app=client /upstream | jq -se 'length > 0 and all(.[]; .status == 200)' >/dev/null 2>&1; }
retry 60 broken || die "client still reaches backend"
