restricted() { [ "$(kx get ns secure-apps -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')" = restricted ]; }
check_eventually 120 "reporter: 2 Ready pods" deploy_ready secure-apps reporter 2
check "secure-apps still enforces restricted" restricted
verdict
