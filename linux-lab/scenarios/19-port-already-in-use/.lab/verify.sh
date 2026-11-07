check_eventually 10 "nginx is active" active nginx
check "port 80 is served by nginx" sx 'curl -sI localhost/ | grep -qi "^server: nginx"'
check "the old listener is gone and not enabled at boot" \
  sx '! systemctl is-active --quiet legacy-status.socket && ! systemctl is-enabled --quiet legacy-status.socket'
verdict
