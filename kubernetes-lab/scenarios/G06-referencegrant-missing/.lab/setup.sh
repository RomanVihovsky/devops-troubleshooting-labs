# G06: an HTTPRoute in web-front points at a Service in web-back, and there's no ReferenceGrant
kns web-front web-back
kx -n web-back create deployment api --image=registry.lab:5000/lab/labapp:1.4 --dry-run=client -o yaml \
  | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); d["spec"]["template"]["spec"]["containers"][0]["env"] = [{"name": "APP_NAME", "value": "backend-api"}]
print(yaml.safe_dump(d))' | ka -f -
kx -n web-back create service clusterip api --tcp=8080:8080 --dry-run=client -o yaml | ka -f -
ka -f route.yaml
denied() { kx -n web-front get httproute frontdoor -o jsonpath='{.status.parents[*].conditions[?(@.type=="ResolvedRefs")].reason}' | grep -q RefNotPermitted; }
retry 90 denied || die "the reference is not refused"
