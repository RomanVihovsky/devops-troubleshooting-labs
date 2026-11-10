kx apply -f forms.yaml >/dev/null
wait_rollout forms deploy/forms
gone() { ! kx -n forms get pvc forms-data >/dev/null 2>&1; }
retry 120 gone || true
