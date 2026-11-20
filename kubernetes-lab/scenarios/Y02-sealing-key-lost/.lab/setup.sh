# Y02: the sealing key Secrets deleted, the controller restarted (a new key), demo-auth gone
[ -s "$SEALED_KEY" ] || die "no sealing key backup in $SEALED_KEY"
cur=$(kx -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o jsonpath='{.items[0].data.tls\.crt}')
grep -q "$cur" "$SEALED_KEY" || die "the backup in $SEALED_KEY is not the current sealing key"
remember y02_cert "$cur"
remember y02_main "$(gx /repos/lab/gitops/branches/main | jq -r .commit.id)"
kx -n kube-system delete secrets -l sealedsecrets.bitnami.com/sealed-secrets-key >/dev/null
kx -n kube-system rollout restart deploy/sealed-secrets-controller >/dev/null
kx -n kube-system rollout status deploy/sealed-secrets-controller --timeout=180s >/dev/null
newkey() { [ -n "$(kx -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o name)" ]; }
retry 60 newkey || die "the controller made no new key"
kx -n demo delete secret demo-auth --ignore-not-found >/dev/null
kx -n demo annotate sealedsecret demo-auth lab.k8slab/touched="$(date +%s)" --overwrite >/dev/null
kx -n demo rollout restart deploy >/dev/null 2>&1 || true
failing() { [ "$(kx -n demo get sealedsecret demo-auth -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}')" = False ]; }
retry 120 failing || die "demo-auth still decrypts"
