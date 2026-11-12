# T04: a client on k8s-w1, a web pod on k8s-w3, a Service in between
kns t04
render "$SCN/manifests/t04.yaml" AGNHOST="$AGNHOST_IMAGE" | ka -f -
render "$SCN/manifests/t04.yaml" AGNHOST="$AGNHOST_IMAGE" > t04.yaml   # the workspace copy, image filled in
wait_rollout t04 deploy/web
kx -n t04 wait --for=condition=Ready pod/client --timeout=120s >/dev/null
svc_programmed() { [ -n "$(nx k8s-w1 "iptables -t nat -S KUBE-SERVICES | grep t04/web" </dev/null)" ]; }
retry 60 svc_programmed || die "kube-proxy on k8s-w1 never programmed t04/web"
