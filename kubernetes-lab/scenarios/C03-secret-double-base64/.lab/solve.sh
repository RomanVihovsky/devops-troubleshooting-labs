pw=$(kx -n cart get secret redis-auth -o jsonpath='{.data.password}' | base64 -d)
cat > cart-secret.yaml <<YML
apiVersion: v1
kind: Secret
metadata: {name: cart-redis, namespace: cart}
type: Opaque
stringData:
  password: $pw
YML
kx -n cart delete secret cart-redis >/dev/null; kx apply -f cart-secret.yaml >/dev/null
kx -n cart rollout restart deploy/cart >/dev/null
wait_rollout cart deploy/cart 240
