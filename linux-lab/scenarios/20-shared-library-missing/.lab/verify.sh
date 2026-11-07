check "library still lives in /opt/vendor/lib (not copied back)" \
  sx 'ls /opt/vendor/lib/libjq.so.1* >/dev/null && ! ls /usr/lib/x86_64-linux-gnu/libjq.so.1* /usr/lib/libjq.so.1* /lib/x86_64-linux-gnu/libjq.so.1* 2>/dev/null | grep -q .'
check "jq works for admin"  as_user admin 'jq --version'
check "jq works for deploy" as_user deploy 'jq --version'
check "jq works in a systemd service" sx 'systemctl start report.service && grep -q jq /var/lib/report/last-run'
verdict
