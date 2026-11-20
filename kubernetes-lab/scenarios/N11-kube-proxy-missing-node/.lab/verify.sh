from_node() {   # a probe pod pinned to node $1 connects to the Service
  KX_TIMEOUT='' kx -n pricing run "lab-probe-$RANDOM" --rm -i --restart=Never --quiet --image="$AGNHOST_IMAGE" \
    --labels="$LAB_LABEL=$LAB_ID" --overrides="{\"spec\":{\"nodeSelector\":{\"kubernetes.io/hostname\":\"$1\"}}}" \
    --command -- /agnhost connect --timeout 3s pricing.pricing.svc:8080 >/dev/null 2>&1
}
everywhere() { [ "$(kx -n kube-system get ds kube-proxy -o jsonpath='{.status.numberReady}/{.status.desiredNumberScheduled}' 2>/dev/null)" = 4/4 ]; }
check_eventually 120 "kube-proxy runs on all 4 nodes" everywhere
for n in k8s-w1 k8s-w2 k8s-w3; do
  check_eventually 30 "pricing.pricing.svc:8080 reachable from a pod on $n" from_node "$n"
done
verdict
