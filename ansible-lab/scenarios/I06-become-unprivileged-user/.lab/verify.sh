owned() { [ "$(nx app1 "stat -c '%U %a' /home/acme/app.ini" 2>/dev/null)" = "acme 600" ] && nx app1 "grep -q 'port = 9100' /home/acme/app.ini"; }
check "/home/acme/app.ini exists, owned by acme, 0600" owned
check "site.yml converges" converged site.yml
check "no world-readable temp file fallback" not ws_has 'allow_world_readable_tmpfiles|ALLOW_WORLD_READABLE_TMPFILES'
verdict
