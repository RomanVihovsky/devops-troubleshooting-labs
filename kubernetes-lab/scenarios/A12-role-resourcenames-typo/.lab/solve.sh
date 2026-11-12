sed -i 's/resourceNames: \[db-cred\]/resourceNames: [db-creds]/' payroll.yaml
kx apply -f payroll.yaml >/dev/null
kx -n payroll delete job secret-sync --wait=true >/dev/null
kx apply -f payroll.yaml >/dev/null
kx -n payroll wait --for=condition=Complete job/secret-sync --timeout=120s >/dev/null
