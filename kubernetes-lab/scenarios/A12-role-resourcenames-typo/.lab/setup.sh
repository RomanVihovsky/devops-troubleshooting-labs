# A12: Role resourceNames typo (db-cred); the Job fails, the pod mount (kubelet, node authorizer) works
kns payroll
kx -n payroll create secret generic db-creds --from-literal=password="$(openssl rand -hex 8)" --dry-run=client -o yaml | ka -f -
kx -n payroll create secret generic payroll-bank --from-literal=iban=XX00TEST --dry-run=client -o yaml | ka -f -
ka -f payroll.yaml
wait_rollout payroll deploy/app
failed() { [ "$(kx -n payroll get job secret-sync -o jsonpath='{.status.conditions[?(@.type=="Failed")].status}')" = True ]; }
retry 180 failed || die "secret-sync did not fail"
