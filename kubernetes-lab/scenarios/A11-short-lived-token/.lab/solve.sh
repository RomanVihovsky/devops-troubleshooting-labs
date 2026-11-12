kx -n ci2 apply -f - >/dev/null <<'YML'
apiVersion: v1
kind: Secret
metadata: {name: ci-bot-token, annotations: {kubernetes.io/service-account.name: ci-bot}}
type: kubernetes.io/service-account-token
YML
filled() { [ -n "$(kx -n ci2 get secret ci-bot-token -o jsonpath='{.data.token}')" ]; }
retry 30 filled || die "the token Secret was not filled"
kx -n ci2 get secret ci-bot-token -o jsonpath='{.data.token}' | base64 -d > ci-token.txt
