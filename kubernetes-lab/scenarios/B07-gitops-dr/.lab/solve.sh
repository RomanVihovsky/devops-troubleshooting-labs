nx k8s-gw 'tar -xzf "$(ls /var/backups/openbao/etc-openbao-*.tgz | tail -1)" -C / etc/openbao/unseal.key && systemctl restart openbao' </dev/null
retry 60 bao_unsealed || die "OpenBao still sealed"
pw=$(bx kv get -mount=secret -field=password ci/gitea-argocd)
kx -n argocd create secret generic repo-gitops --from-literal=type=git --from-literal=url="$GITOPS_REPO" \
  --from-literal=username=argocd --from-literal=password="$pw" --dry-run=client -o yaml \
  | kx label --local -f - argocd.argoproj.io/secret-type=repository -o yaml | kx apply -f - >/dev/null
kx -n argocd patch application lab-apps --type merge -p '{"spec":{"source":{"targetRevision":"main"}}}' >/dev/null
kx apply -f "$SEALED_KEY" >/dev/null
kx -n kube-system rollout restart deploy/sealed-secrets-controller >/dev/null
kx -n kube-system rollout status deploy/sealed-secrets-controller --timeout=180s >/dev/null
kx -n demo annotate sealedsecret demo-auth lab.k8slab/touched="$(date +%s)" --overwrite >/dev/null
ss_ok() { [ "$(kx -n demo get sealedsecret demo-auth -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null)" = True ]; }
if ! retry 60 ss_ok; then   # a controller that started before the key was there: once more
  kx -n kube-system rollout restart deploy/sealed-secrets-controller >/dev/null
  kx -n kube-system rollout status deploy/sealed-secrets-controller --timeout=180s >/dev/null
  retry 90 ss_ok || true
fi
kx annotate clustersecretstore openbao force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true
# an automated sync that failed while the repo was unreachable is never retried for the same revision: sync
for a in lab-apps demo shop; do argo_refresh "$a"; done
sleep 5
for a in lab-apps demo shop; do argo_sync "$a"; done
retry 240 argo_app_ok shop || true
kx -n demo rollout restart deploy >/dev/null 2>&1 || true
retry 120 demo_auth_ok || true
