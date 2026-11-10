# Y01: the new token sealed (strict) for demo-staging, committed for demo; staging got it too and works
printf 'tok-%s' "$(openssl rand -hex 12)" > new-token.txt
remember y01_new "$(cat new-token.txt)"
ct=$(kubeseal --raw --cert "$SEALED_CERT" --scope strict --namespace demo-staging --name demo-auth --from-file=new-token.txt)
gitops_commit "demo: rotate the API token (SEC-118)" <<SNIP
sed -i "s|^\\(\\s*auth-token: \\).*|\\1$ct|" envs/demo/values.yaml
grep -q "$ct" envs/demo/values.yaml
SNIP
kns demo-staging
ka -f - <<YML
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata: {name: demo-auth, namespace: demo-staging}
spec:
  encryptedData: {auth-token: "$ct"}
  template: {metadata: {name: demo-auth, namespace: demo-staging}}
YML
argo_refresh demo
failing() { kx -n demo get sealedsecret demo-auth -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null | grep -qx False; }
retry 180 failing || die "the demo SealedSecret never failed to decrypt"
