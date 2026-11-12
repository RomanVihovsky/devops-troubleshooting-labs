source "$SCN/.lab/facts.sh"
cat > answers.yaml <<YML
containerd_version_w2: "$(f_containerd_w2)"
zone_w3: $(f_zone_w3)
argocd_ip: $(f_argocd_ip)
api_backend: "$(f_api_backend)"
default_storageclass: $(f_default_sc)
l01_reset: $(f_l01_reset)
YML
kx -n t01 create deployment hello --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --port=8080 >/dev/null
kx -n t01 expose deployment hello --port=80 --target-port=8080 >/dev/null
wait_rollout t01 deploy/hello
