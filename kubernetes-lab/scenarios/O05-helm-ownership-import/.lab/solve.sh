kx -n importx label svc web app.kubernetes.io/managed-by=Helm --overwrite >/dev/null
kx -n importx annotate svc web meta.helm.sh/release-name=web meta.helm.sh/release-namespace=importx --overwrite >/dev/null
helm install web "$LAB_DIR/charts/labapp" -n importx -f values.yaml --wait --timeout 3m >/dev/null
