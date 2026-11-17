kx -n orders-db delete sts postgres --wait=true >/dev/null
kx -n orders-db delete pvc data-postgres-0 --ignore-not-found --wait=true >/dev/null
kx -n orders-db delete service postgres --ignore-not-found >/dev/null
python3 - postgres.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
for d in docs:
    if d["kind"] == "Service":
        d["spec"]["clusterIP"] = "None"
    if d["kind"] == "StatefulSet":
        d["spec"]["volumeClaimTemplates"][0]["spec"].pop("storageClassName", None)
        for e in d["spec"]["template"]["spec"]["containers"][0]["env"]:
            if e["name"] == "POSTGRES_PASSWORD":
                e["valueFrom"]["secretKeyRef"]["key"] = "postgres-password"
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
ka -f postgres.yaml
retry 180 deploy_ready orders-db orders 1 || true
