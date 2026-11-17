kx apply -f "$SEALED_KEY" >/dev/null
kx -n kube-system rollout restart deploy/sealed-secrets-controller >/dev/null
kx -n kube-system rollout status deploy/sealed-secrets-controller --timeout=180s >/dev/null
kx -n demo annotate sealedsecret demo-auth lab.k8slab/touched="$(date +%s)" --overwrite >/dev/null
retry 120 kx -n demo get secret demo-auth || true
kx -n demo rollout restart deploy >/dev/null 2>&1 || true
retry 120 demo_auth_ok || true
