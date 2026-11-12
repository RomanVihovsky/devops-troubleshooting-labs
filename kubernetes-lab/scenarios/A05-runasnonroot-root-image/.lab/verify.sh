nonroot_kept() { [ "$(kx -n payments-ui get deploy payments-ui -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}{.spec.template.spec.containers[0].securityContext.runAsNonRoot}' | grep -c true)" -ge 1 ]; }
uid_nonzero() { local u; u=$(kx -n payments-ui exec deploy/payments-ui -- id -u 2>/dev/null); [ -n "$u" ] && [ "$u" != 0 ]; }
check_eventually 120 "payments-ui Ready" deploy_ready payments-ui payments-ui
check "runAsNonRoot still set" nonroot_kept
check "the container runs as a non-root user" uid_nonzero
verdict
