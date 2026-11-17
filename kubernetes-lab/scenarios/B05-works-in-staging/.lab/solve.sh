for o in secret/regcred configmap/web-config; do
  kx -n web-staging get "$o" -o json | jq '.metadata |= {name: .name, namespace: "web-prod"}' | ka -f -
done
sed -i -e 's|registry.lab:5001/lab/labapp:1.6 .*|registry.lab:5001/lab/labapp:1.4|' -e 's|ingressClassName: nginx|ingressClassName: traefik|' web.yaml
ka -f web.yaml
retry 180 deploy_ready web-prod web 2 || true
