# A11: the CI token was a TokenRequest bound to a runner pod; the pod is gone, so the token is rejected
kns ci2
kx -n ci2 create serviceaccount ci-bot --dry-run=client -o yaml | ka -f -
kx -n ci2 create rolebinding ci-bot-view --clusterrole=view --serviceaccount=ci2:ci-bot --dry-run=client -o yaml | ka -f -
ka -f - <<'YML'
apiVersion: v1
kind: Pod
metadata: {name: runner-7f9c, namespace: ci2}
spec:
  serviceAccountName: ci-bot
  containers: [{name: runner, image: docker.io/library/busybox:1.37, command: ["sh", "-c", "sleep 3600"]}]
YML
retry 60 kx -n ci2 wait --for=condition=Ready pod/runner-7f9c --timeout=5s || die "runner not up"
uid=$(kx -n ci2 get pod runner-7f9c -o jsonpath='{.metadata.uid}')
kx -n ci2 create token ci-bot --duration=48h --bound-object-kind=Pod --bound-object-name=runner-7f9c --bound-object-uid="$uid" > ci-token.txt
kx -n ci2 delete pod runner-7f9c --grace-period=0 --force >/dev/null 2>&1
ca=$(mktemp); kx config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$ca"
srv=$(kx config view --minify -o jsonpath='{.clusters[0].cluster.server}')
rejected() { ! kubectl --kubeconfig=/dev/null --server="$srv" --certificate-authority="$ca" --token="$(cat ci-token.txt)" -n ci2 get pods >/dev/null 2>&1; }
retry 60 rejected || die "the token still works"
rm -f "$ca"
