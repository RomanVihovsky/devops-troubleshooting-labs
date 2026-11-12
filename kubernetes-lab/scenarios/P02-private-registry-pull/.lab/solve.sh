kx -n ci get secret regcred -o json | jq 'del(.metadata.namespace, .metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.managedFields)' \
  | kx -n vendor apply -f - >/dev/null
python3 - vendor-api.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
d["spec"]["template"]["spec"]["imagePullSecrets"] = [{"name": "regcred"}]
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx apply -f vendor-api.yaml >/dev/null
wait_rollout vendor deploy/vendor-api 180
