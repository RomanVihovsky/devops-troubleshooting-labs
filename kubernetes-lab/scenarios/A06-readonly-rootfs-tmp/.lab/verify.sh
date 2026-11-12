ro_kept() { [ "$(kx -n invoices get deploy invoices -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')" = true ]; }
check_eventually 120 "invoices Ready" deploy_ready invoices invoices
check_eventually 150 "no new restarts for 60 s" stable_for 60 invoices app=invoices
check "readOnlyRootFilesystem still true" ro_kept
verdict
