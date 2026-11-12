last=$(helm history web -n helmx -o json | jq -r '[.[] | select(.status == "deployed" or .status == "superseded")] | last | .revision')
helm rollback web "$last" -n helmx >/dev/null 2>&1 || true
helm upgrade web "$LAB_DIR/charts/labapp" -n helmx -f values.yaml --wait --timeout 3m >/dev/null
