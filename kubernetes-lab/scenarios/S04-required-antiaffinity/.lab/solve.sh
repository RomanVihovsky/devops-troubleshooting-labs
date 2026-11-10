python3 - <<'PY'
import yaml
d = yaml.safe_load(open("gateway.yaml")); s = d["spec"]["template"]["spec"]
s.pop("affinity")
# DoNotSchedule = a deterministic 2/2/1; Honor = the tainted control plane is not an (empty) domain
s["topologySpreadConstraints"] = [{"maxSkew": 1, "topologyKey": "kubernetes.io/hostname", "whenUnsatisfiable": "DoNotSchedule",
                                   "nodeTaintsPolicy": "Honor", "labelSelector": {"matchLabels": {"app": "gateway"}}}]
yaml.safe_dump(d, open("gateway.yaml", "w"), sort_keys=False)
PY
kx apply -f gateway.yaml >/dev/null
# the old pods' REQUIRED anti-affinity also repels the new pods (it is symmetric), and the old ReplicaSet can't
# shrink (3 of 5 available < 5 - maxUnavailable): the rollout deadlocks. Remove the old ReplicaSet.
observed() { [ "$(kx -n gateway get deploy gateway -o jsonpath='{.status.observedGeneration}')" = "$(kx -n gateway get deploy gateway -o jsonpath='{.metadata.generation}')" ]; }
retry 30 observed || die "the Deployment controller never saw the change"
rev=$(kx -n gateway get deploy gateway -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
for rs in $(kx -n gateway get rs -l app=gateway -o name); do
  [ "$(kx -n gateway get "$rs" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')" = "$rev" ] || kx -n gateway delete "$rs" >/dev/null
done
wait_rollout gateway deploy/gateway
