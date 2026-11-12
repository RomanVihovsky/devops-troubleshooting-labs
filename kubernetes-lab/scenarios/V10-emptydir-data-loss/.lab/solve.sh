python3 - <<'PY'
import yaml
d = yaml.safe_load(open("notes.yaml"))
d["spec"]["strategy"] = {"type": "Recreate"}
d["spec"]["template"]["spec"]["volumes"] = [{"name": "data", "persistentVolumeClaim": {"claimName": "notes-data"}}]
pvc = {"apiVersion": "v1", "kind": "PersistentVolumeClaim", "metadata": {"name": "notes-data", "namespace": "notes"},
       "spec": {"accessModes": ["ReadWriteOnce"], "resources": {"requests": {"storage": "64Mi"}}}}
yaml.safe_dump_all([pvc, d], open("notes.yaml", "w"), sort_keys=False)
PY
kx apply -f notes.yaml >/dev/null
wait_rollout notes deploy/notes 180
