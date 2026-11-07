check "nginx -t passes" sx 'nginx -t'
check "client: curl https://srv.lab/ verifies and succeeds" cx 'curl -fsS --max-time 5 https://srv.lab/ | grep -q "secure shop OK"'
verdict
