# O06: the Deployment was deleted with --cascade=orphan; its ReplicaSet (and pods) live on
kns retired
for a in oldapp:3 keeper:1; do
  kx -n retired create deployment "${a%%:*}" --image=registry.lab:5000/lab/labapp:1.4 --replicas="${a##*:}" --dry-run=client -o yaml | ka -f -
  wait_rollout retired "deploy/${a%%:*}"
done
kx -n retired delete deployment oldapp --cascade=orphan >/dev/null
