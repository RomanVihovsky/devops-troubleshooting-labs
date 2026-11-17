# B07: OpenBao sealed (seal key replaced), Argo CD's repo Secret gone, the sealing key regenerated, root app on "master"
[ -s "$SEALED_KEY" ] || die "no sealing key backup in $SEALED_KEY"
remember b07_main "$(gx /repos/lab/gitops/branches/main | jq -r .commit.id)"
remember b07_cert "$(kx -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath='{.items[0].data.tls\.crt}')"
bx kv put -mount=secret ci/gitea-argocd username=argocd password="$(cat "$GITEA_DIR/argocd-password")" >/dev/null
# Argo CD: no repo credentials, root app on a branch that doesn't exist
kx -n argocd delete secret repo-gitops --ignore-not-found >/dev/null
kx -n argocd patch application lab-apps --type merge -p '{"spec":{"source":{"targetRevision":"master"}}}' >/dev/null
# Sealed Secrets: new key, demo-auth gone
kx -n kube-system delete secrets -l sealedsecrets.bitnami.com/sealed-secrets-key >/dev/null
kx -n kube-system rollout restart deploy/sealed-secrets-controller >/dev/null
kx -n kube-system rollout status deploy/sealed-secrets-controller --timeout=180s >/dev/null
kx -n demo delete secret demo-auth --ignore-not-found >/dev/null
kx -n demo annotate sealedsecret demo-auth lab.k8slab/touched="$(date +%s)" --overwrite >/dev/null
kx -n demo rollout restart deploy >/dev/null 2>&1 || true
# OpenBao: seal key replaced (backup kept on gw)
nx k8s-gw 'set -e; mkdir -p /var/backups/openbao
  tar -czf "/var/backups/openbao/etc-openbao-$(date -d yesterday +%F).tgz" -C / etc/openbao
  openssl rand -out /etc/openbao/unseal.key 32; chown openbao:openbao /etc/openbao/unseal.key; chmod 600 /etc/openbao/unseal.key
  systemctl restart openbao' </dev/null
sealed() { [ "$(bao_api sys/seal-status | jq -r .sealed)" = true ]; }
retry 60 sealed || die "OpenBao is not sealed"
for a in lab-apps demo shop; do argo_refresh "$a"; done
kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s)" --overwrite >/dev/null 2>&1 || true
broken() { ! argo_app_ok demo || ! argo_app_ok lab-apps; }
retry 180 broken || die "Argo CD still looks fine"
