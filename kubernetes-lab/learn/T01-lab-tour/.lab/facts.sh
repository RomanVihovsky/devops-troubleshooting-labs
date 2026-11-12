# T01: the live truth behind the answers (sourced by verify and solve)
f_containerd_w2() { kx get node k8s-w2 -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}' | sed 's|^containerd://||'; }
f_zone_w3() { kx get node k8s-w3 -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'; }
f_argocd_ip() { kx -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'; }
f_api_backend() { nx k8s-gw "awk '\$1 == \"server\" { print \$3 }' /etc/haproxy/haproxy.cfg | head -1" </dev/null; }
f_default_sc() { kx get storageclass -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{end}'; }
f_l01_reset() { yget reset "$(lab_dir L01)"; }
