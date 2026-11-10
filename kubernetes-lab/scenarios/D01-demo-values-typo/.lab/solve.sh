gitops_commit "demo: fix the release - tag 1.4, app.greeting (INC-2231)" student <<'SNIP'
python3 - <<'PY'
import yaml
f = "envs/demo/values.yaml"; d = yaml.safe_load(open(f))
d["image"]["tag"] = "1.4"
d["app"].pop("greting", None); d["app"]["greeting"] = "Bonjour"
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
SNIP
argo_refresh demo
retry 240 argo_app_ok demo || true
