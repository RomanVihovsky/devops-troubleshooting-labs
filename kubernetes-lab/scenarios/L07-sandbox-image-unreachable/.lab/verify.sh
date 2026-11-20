sandbox_present() {
  nx k8s-w2 'img=$(sed -n "s/^ *sandbox = '"'"'\([^'"'"']*\)'"'"'.*/\1/p" /etc/containerd/config.toml | head -1); [ -n "$img" ] && crictl inspecti "$img" >/dev/null 2>&1' </dev/null
}
fresh() {
  [ "$(kx -n shipping get pod lab-l07-fresh -o jsonpath='{.status.phase}' 2>/dev/null)" = Running ]
}
check_eventually 150 "shipping-api: 2 Ready pods" deploy_ready shipping shipping-api 2
check "w2's configured sandbox image is present on the node" sandbox_present
kx -n shipping delete pod lab-l07-fresh --ignore-not-found --wait=true >/dev/null 2>&1
kx -n shipping run lab-l07-fresh --image=registry.lab:5000/lab/labapp:1.4 --restart=Never \
  --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"k8s-w2"}}}' --labels="$LAB_LABEL=$LAB_ID" >/dev/null 2>&1
check_eventually 90 "a brand-new pod on k8s-w2 starts" fresh
kx -n shipping delete pod lab-l07-fresh --wait=false >/dev/null 2>&1
verdict
