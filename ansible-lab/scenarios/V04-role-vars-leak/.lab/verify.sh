check "web1 serves the shop on 8080" eval 'http_get http://web1:8080/ | grep -qx shop'
check "web1 serves metrics on 9100" eval 'http_get http://web1:9100/ | grep -qx "metrics up"'
check "ansible-lint var-naming passes for both roles" eval 'ctl_ci "ansible-lint --offline --nocolor -t var-naming roles/" >> "$VERIFY_LOG" 2>&1'
check "site.yml converges" converged site.yml
verdict
